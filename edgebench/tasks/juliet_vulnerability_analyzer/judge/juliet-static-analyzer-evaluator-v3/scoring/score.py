#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, math, re, subprocess, sys, time
from pathlib import Path
from typing import Any

FORBIDDEN_RE = re.compile(r"\b(codeql|joern|semgrep|infer|cppcheck|clang\s+--analyze|scan-build)\b", re.I)
NETWORK_RE = re.compile(r"\b(curl|wget|git\s+clone|requests\.|urllib\.|socket\.)\b", re.I)
CWE_FAMILY = {
    'CWE-121': 'stack_buffer_overflow',
    'CWE-122': 'heap_buffer_overflow',
    'CWE-190': 'integer_overflow',
    'CWE-476': 'null_pointer_deref',
    'CWE-416': 'use_after_free',
    'CWE-78': 'command_injection',
}

def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows=[]
    with path.open('r',encoding='utf-8') as f:
        for line_no,line in enumerate(f,1):
            line=line.strip()
            if not line: continue
            obj=json.loads(line)
            if not isinstance(obj,dict): raise ValueError(f'{path}:{line_no}: expected object')
            rows.append(obj)
    return rows

def label_key(x: dict[str, Any]) -> tuple[str,str,int]:
    return (str(x.get('case_id')), str(x.get('cwe')), int(x.get('sink_stmt')))

def numeric_list(xs: Any) -> list[int]:
    out=[]
    if not isinstance(xs, list):
        return out
    for x in xs:
        if isinstance(x, int): out.append(x)
        elif isinstance(x, str) and x.lstrip('-').isdigit(): out.append(int(x))
    return out

def check_forbidden(root: Path) -> tuple[bool,list[str]]:
    hits=[]
    if not root.exists(): return True,[f'missing submission root {root}']
    for p in root.rglob('*'):
        if not p.is_file() or p.suffix not in {'.py','.sh'}: continue
        if any(part in {'out','__pycache__','.pytest_cache'} for part in p.parts): continue
        text=p.read_text(encoding='utf-8',errors='ignore')
        if FORBIDDEN_RE.search(text): hits.append(f'forbidden analyzer backend reference: {p}')
        if NETWORK_RE.search(text): hits.append(f'forbidden network/provenance command reference: {p}')
    return bool(hits),hits[:20]

def run_analyzer(analyzer: Path, facts: Path, timeout: float) -> tuple[bool,dict[str,Any],str,float]:
    out_dir=analyzer.parent/'out'; out_dir.mkdir(parents=True,exist_ok=True)
    out_path=out_dir/'findings.json'
    if out_path.exists(): out_path.unlink()
    start=time.monotonic()
    try:
        proc=subprocess.run([sys.executable,str(analyzer),'--input',str(facts),'--output',str(out_path)], cwd=str(Path.cwd()), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    except subprocess.TimeoutExpired:
        return False,{'findings':[]},f'timeout after {timeout}s',timeout
    dur=time.monotonic()-start
    if proc.returncode!=0:
        return False,{'findings':[]},f'analyzer exit {proc.returncode}; stderr={proc.stderr[-2000:]}',dur
    if not out_path.exists(): return False,{'findings':[]},'missing output file',dur
    try:
        payload=json.loads(out_path.read_text(encoding='utf-8'))
    except Exception as exc:
        return False,{'findings':[]},f'malformed output JSON: {exc}',dur
    if not isinstance(payload,dict) or not isinstance(payload.get('findings'),list):
        return False,{'findings':[]},'output must be {"findings": [...]}' ,dur
    return True,payload,'',dur

def normalize(payload: dict[str,Any], case_ids: set[str]) -> tuple[list[dict[str,Any]],int,int]:
    valid=[]; invalid=0; duplicates=0; seen=set()
    for item in payload.get('findings',[]):
        if not isinstance(item,dict): invalid+=1; continue
        try:
            trace=numeric_list(item.get('trace',[]))
            clean={
                'case_id':str(item['case_id']),
                'cwe':str(item['cwe']),
                'sink_stmt':int(item['sink_stmt']),
                'source_stmt':int(item['source_stmt']),
                'trace':trace,
                'confidence':float(item.get('confidence',0.0) or 0.0),
            }
        except Exception:
            invalid+=1; continue
        if clean['case_id'] not in case_ids or not re.fullmatch(r'CWE-\d+', clean['cwe']):
            invalid+=1; continue
        key=label_key(clean)
        if key in seen:
            duplicates+=1; continue
        seen.add(key); valid.append(clean)
    return valid,invalid,duplicates

def f1(tp:int, fp:int, fn:int)->float:
    return 0.0 if (2*tp+fp+fn)==0 else (2*tp)/(2*tp+fp+fn)

def subseq(got:list[int], expected:list[int])->bool:
    if not expected or not got: return False
    pos=0
    for x in got:
        if pos < len(expected) and int(x)==int(expected[pos]): pos+=1
    return pos==len(expected)

def stmt_ids_by_case(cases:list[dict[str,Any]]) -> dict[str,set[int]]:
    out={}
    for c in cases:
        ids=set()
        for s in c.get('stmts',[]):
            try: ids.add(int(s.get('stmt_id')))
            except Exception: pass
        out[str(c.get('case_id'))]=ids
    return out

def trace_valid(pred:dict[str,Any], label:dict[str,Any], stmt_ids:set[int]) -> tuple[bool,str]:
    expected=numeric_list(label.get('trace',[]))
    source=int(label.get('source_stmt', expected[0] if expected else label.get('sink_stmt')))
    sink=int(label.get('sink_stmt'))
    got=pred.get('trace',[])
    if int(pred.get('source_stmt',-1)) != source:
        return False,'wrong_source'
    if not got:
        return False,'missing_trace'
    if got[0] != source:
        return False,'trace_not_source_start'
    if got[-1] != sink:
        return False,'trace_not_sink_end'
    if any(x not in stmt_ids for x in got):
        return False,'trace_unknown_stmt'
    if len(set(got)) != len(got):
        return False,'trace_repeats_node'
    max_len=max(4, len(expected)+2, int(math.ceil(len(expected)*2.5)))
    if len(got) > max_len:
        return False,'trace_too_broad'
    if expected and not subseq(got, expected):
        return False,'trace_misses_required_witness'
    return True,'ok'

def evaluate(cases:list[dict[str,Any]], labels:list[dict[str,Any]], preds:list[dict[str,Any]], *, ok=True, dur=0.0, timeout=30.0, invalid=0, dup=0, forbidden=False) -> dict[str,Any]:
    label_by={label_key(l):l for l in labels}; pred_by={label_key(p):p for p in preds}
    lk=set(label_by); pk=set(pred_by)
    tp=lk & pk; fp=pk-lk; fn=lk-pk
    finding_f1=f1(len(tp),len(fp),len(fn)); recall=(len(tp)/len(lk) if lk else 1.0); precision=(len(tp)/(len(tp)+len(fp)) if (len(tp)+len(fp)) else 1.0)
    case_ids={str(c['case_id']) for c in cases}; pos_case={str(l['case_id']) for l in labels}; neg_case=case_ids-pos_case; pred_case={str(p['case_id']) for p in preds}
    negative_precision=(sum(1 for c in neg_case if c not in pred_case)/len(neg_case) if neg_case else 1.0)
    negative_component=negative_precision if recall>=0.05 else negative_precision*min(1.0,recall/0.05)
    adv_lk={label_key(l) for l in labels if l.get('advanced',True)}
    adv_pk={k for k in pk if k in adv_lk}
    adv_f1=f1(len(adv_lk & adv_pk),len(adv_pk-adv_lk),len(adv_lk-adv_pk))
    ids=stmt_ids_by_case(cases)
    trace_req=0; trace_ok=0; trace_invalid=0; reasons={}
    for k in tp:
        expected=numeric_list(label_by[k].get('trace',[]))
        if expected:
            trace_req+=1
            good, reason=trace_valid(pred_by[k], label_by[k], ids.get(k[0],set()))
            if good:
                trace_ok+=1
            else:
                trace_invalid+=1; reasons[reason]=reasons.get(reason,0)+1
    trace_quality=(trace_ok/trace_req if trace_req else 1.0)
    perf=1.0 if ok and dur<=timeout else 0.0
    spam=0.0
    if len(preds)>max(20,3*max(1,len(labels))): spam+=min(25.0,(len(preds)-3*len(labels))/max(1,len(labels))*12.0)
    spam+=min(8.0,dup*0.05)+min(12.0,invalid*0.2)
    if forbidden: spam+=100.0
    score=35*finding_f1+20*negative_component+20*adv_f1+15*trace_quality+10*perf-spam
    # Original design requires trace quality: sink-only or broad all-prior traces cannot obtain a high score.
    if trace_req and trace_quality < 0.25:
        score=min(score,50.0)
    elif trace_req and trace_quality < 0.60:
        score=min(score,70.0)
    if recall<0.02: score=min(score,10.0+recall*250.0)
    score=max(0.0,min(100.0,score))
    by_cwe={}
    for cwe in sorted({l['cwe'] for l in labels}|{p['cwe'] for p in preds}):
        lset={k for k in lk if k[1]==cwe}; pset={k for k in pk if k[1]==cwe}; by_cwe[cwe]={'tp':len(lset&pset),'fp':len(pset-lset),'fn':len(lset-pset),'f1':round(f1(len(lset&pset),len(pset-lset),len(lset-pset)),4)}
    fam_by_label={label_key(l):str(l.get('advanced_kind') or CWE_FAMILY.get(str(l.get('cwe')),'unknown')) for l in labels}
    fams=sorted(set(fam_by_label.values())|{CWE_FAMILY.get(k[1],'unknown') for k in pk})
    by_fam={}
    for fam in fams:
        lset={k for k in lk if fam_by_label.get(k)==fam}; pset={k for k in pk if (fam_by_label.get(k) if k in lk else CWE_FAMILY.get(k[1],'unknown'))==fam}
        by_fam[fam]={'tp':len(lset&pset),'fp':len(pset-lset),'fn':len(lset-pset),'f1':round(f1(len(lset&pset),len(pset-lset),len(lset-pset)),4)}
    return {'raw_passed':len(tp),'raw_total':len(labels),'weighted_passed':int(round(score*100)),'weighted_total':10000,'score':score,'precision':precision,'recall':recall,'finding_f1':finding_f1,'negative_precision':negative_precision,'advanced_f1':adv_f1,'trace_quality':trace_quality,'trace_valid_tp':trace_ok,'trace_invalid_findings':trace_invalid,'trace_invalid_reasons':reasons,'trace_required':trace_req,'tp':len(tp),'fp':len(fp),'fn':len(fn),'invalid_findings':invalid,'duplicate_findings':dup,'spam_penalty':spam,'duration':dur,'per_cwe':by_cwe,'per_family':by_fam}

def print_metrics(m:dict[str,Any], status:str, error:str=''):
    print(f"RAW_PASSED={m.get('raw_passed',0)}"); print(f"RAW_TOTAL={m.get('raw_total',0)}")
    print(f"WEIGHTED_PASSED={m.get('weighted_passed',0)}"); print(f"WEIGHTED_TOTAL={m.get('weighted_total',10000)}")
    print(f"SCORE={m.get('score',0.0):.2f}"); print(f"SCORE_STATUS={status}")
    if error: print('ERROR='+error.replace('\n',' ')[:3000])
    for k in ['precision','recall','finding_f1','negative_precision','advanced_f1','trace_quality','trace_valid_tp','trace_invalid_findings','trace_required','tp','fp','fn','invalid_findings','duplicate_findings','spam_penalty','duration']:
        v=m.get(k)
        if isinstance(v,float): print(f'{k.upper()}={v:.4f}')
        elif v is not None: print(f'{k.upper()}={v}')
    if 'trace_invalid_reasons' in m: print('TRACE_INVALID_REASONS='+json.dumps(m['trace_invalid_reasons'],sort_keys=True))
    if 'per_cwe' in m: print('PER_CWE='+json.dumps(m['per_cwe'],sort_keys=True))
    if 'per_family' in m: print('PER_FAMILY='+json.dumps(m['per_family'],sort_keys=True))

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--facts',required=True); ap.add_argument('--labels',required=True); ap.add_argument('--analyzer',required=True); ap.add_argument('--submission-root',required=True); ap.add_argument('--timeout',type=float,default=30.0)
    a=ap.parse_args()
    try:
        cases=load_jsonl(Path(a.facts)); labels=load_jsonl(Path(a.labels))
    except Exception as exc:
        print_metrics({'raw_total':0,'weighted_total':10000},'INFRA_FAIL',str(exc)); sys.exit(2)
    forbidden,hits=check_forbidden(Path(a.submission_root))
    ok,payload,err,dur=run_analyzer(Path(a.analyzer),Path(a.facts),a.timeout)
    if not ok:
        m=evaluate(cases,labels,[],ok=False,dur=dur,timeout=a.timeout,forbidden=forbidden)
        print_metrics(m,'INFRA_FAIL',err); sys.exit(2)
    preds,invalid,dup=normalize(payload,{str(c['case_id']) for c in cases})
    m=evaluate(cases,labels,preds,ok=True,dur=dur,timeout=a.timeout,invalid=invalid,dup=dup,forbidden=forbidden)
    print_metrics(m,'OK','; '.join(hits))
    if forbidden: sys.exit(1)
if __name__=='__main__': main()
