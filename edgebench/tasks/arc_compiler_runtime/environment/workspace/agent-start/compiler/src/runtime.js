function lex(source) {
  return { type: "ArcSource", source: String(source ?? ""), tokens: tokenize(String(source ?? "")) };
}

function parse(input) {
  const source = typeof input === "string" ? input : input?.source ?? "";
  return { type: "Program", source, stmts: splitTopLevel(source).map((text) => ({ type: classify(text), text })) };
}

function createEnv(seed = {}) {
  return { vars: { ...seed } };
}

function interpretWithEnv(program, env = createEnv()) {
  const js = compileProgram(program?.source ?? String(program ?? ""), { expressionResult: true });
  const names = Object.keys(env.vars);
  const values = Object.values(env.vars);
  return Function(...names, `"use strict";\n${js}`)(...values);
}

function generateIR(program) {
  return { type: "ArcIR", source: program?.source ?? String(program ?? "") };
}

function generateJS(ir) {
  return compileProgram(ir?.source ?? String(ir ?? ""), { expressionResult: false });
}

function format(source) {
  return splitTopLevel(source).join(";\n");
}

function lint(source) {
  try {
    parse(lex(source));
    return [];
  } catch (error) {
    return [{ level: "error", message: error.message }];
  }
}

function validateSource(source, options = {}) {
  const max = options.maxSourceSize ?? 1024 * 1024;
  if (String(source ?? "").length > max) throw new Error("source exceeds maximum size");
  return true;
}

function validateToolCall(method, url, options = {}) {
  const allowed = options.allowedToolMethods ?? ["GET", "POST", "PUT", "DELETE"];
  if (!allowed.includes(String(method).toUpperCase())) throw new Error("method not allowed");
  if (url && !/^https?:\/\//.test(String(url))) throw new Error("url must be http(s)");
  return true;
}

function parseArcToml(source) {
  const root = {};
  let current = root;
  for (const raw of String(source ?? "").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const section = line.match(/^\[([^\]]+)\]$/);
    if (section) {
      current = root;
      for (const part of section[1].split(".")) current = current[part] ??= {};
      continue;
    }
    const pair = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(.*)$/);
    if (pair) current[pair[1]] = parseTomlValue(pair[2]);
  }
  return root;
}

function parseTomlValue(text) {
  const s = text.trim();
  if (/^".*"$/.test(s)) return s.slice(1, -1);
  if (s === "true") return true;
  if (s === "false") return false;
  if (/^-?\d+(\.\d+)?$/.test(s)) return Number(s);
  return s;
}

function classify(text) {
  const s = text.trim();
  if (s.startsWith("fn ")) return "Function";
  if (s.startsWith("let ")) return "Let";
  if (s.startsWith("if ")) return "If";
  if (s.startsWith("for ")) return "For";
  if (s.startsWith("while ")) return "While";
  if (s.startsWith("match ")) return "Match";
  return "Expression";
}

function tokenize(source) {
  const out = [];
  let i = 0;
  while (i < source.length) {
    const c = source[i];
    if (/\s/.test(c)) { i++; continue; }
    if (c === "#" || (c === "/" && source[i + 1] === "/")) {
      while (i < source.length && source[i] !== "\n") i++;
      continue;
    }
    if (c === '"' || c === "'") {
      const quote = c; let j = i + 1, value = quote;
      while (j < source.length) {
        value += source[j];
        if (source[j] === "\\" && j + 1 < source.length) value += source[++j];
        else if (source[j] === quote) { j++; break; }
        j++;
      }
      out.push({ type: "string", value }); i = j; continue;
    }
    const two = source.slice(i, i + 2);
    if (["=>", "==", "!=", "<=", ">=", "..", "?.", "|>", "++", "**"].includes(two)) {
      out.push({ type: "op", value: two }); i += 2; continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i + 1; while (/[A-Za-z0-9_]/.test(source[j] ?? "")) j++;
      out.push({ type: "ident", value: source.slice(i, j) }); i = j; continue;
    }
    if (/\d/.test(c)) {
      let j = i + 1; while (/\d|\./.test(source[j] ?? "")) j++;
      out.push({ type: "number", value: source.slice(i, j) }); i = j; continue;
    }
    out.push({ type: "punct", value: c }); i++;
  }
  return out;
}

function splitTopLevel(source) {
  const parts = [];
  let start = 0, depth = 0, quote = "", escape = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i], next = source[i + 1];
    if (quote) {
      if (escape) escape = false;
      else if (c === "\\") escape = true;
      else if (c === quote) quote = "";
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === "#" || (c === "/" && next === "/")) {
      while (i < source.length && source[i] !== "\n") i++;
      continue;
    }
    if ("([{".includes(c)) depth++;
    else if (")]}".includes(c)) depth--;
    else if ((c === ";" || c === "\n") && depth === 0) {
      const chunk = source.slice(start, i).trim();
      if (chunk) parts.push(chunk);
      start = i + 1;
    }
  }
  const tail = source.slice(start).trim();
  if (tail) parts.push(tail);
  return parts;
}

function compileProgram(source, options = {}) {
  const statements = splitTopLevel(stripTypeDeclarations(source));
  let js = runtimePrelude();
  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    const last = i === statements.length - 1;
    js += compileStatement(stmt, last && options.expressionResult) + "\n";
  }
  if (!statements.length && options.expressionResult) js += "return undefined;\n";
  return js;
}

function stripTypeDeclarations(source) {
  return String(source ?? "").split(/\r?\n/).filter((line) => !line.trim().startsWith("type ")).join("\n");
}

function compileStatement(stmt, shouldReturn = false) {
  const s = stmt.trim();
  if (!s) return "";
  let m = s.match(/^let\s+(mut\s+)?([A-Za-z_]\w*)\s*=\s*([\s\S]*)$/);
  if (m) return `${m[1] ? "let" : "const"} ${m[2]} = ${compileExpr(m[3])};${shouldReturn ? `\nreturn ${m[2]};` : ""}`;
  m = s.match(/^fn\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{([\s\S]*)\}$/);
  if (m) return `function ${m[1]}(${params(m[2])}) { ${compileBlock(m[3], true)} }`;
  if (/^[A-Za-z_]\w*\s*=/.test(s) && !/^[A-Za-z_]\w*\s*==/.test(s)) {
    return `${compileAssignment(s)};${shouldReturn ? `\nreturn ${s.split("=")[0].trim()};` : ""}`;
  }
  if (s.startsWith("for ")) return compileFor(s);
  if (s.startsWith("while ")) return compileWhile(s);
  if (s.startsWith("do ")) return compileDo(s);
  if (s.startsWith("use ")) return compileUse(s);
  if (s.startsWith("return ")) return `return ${compileExpr(s.slice(7))};`;
  if (s === "break" || s === "continue") return `${s};`;
  const expr = compileExpr(s);
  return shouldReturn ? `return ${expr};` : `${expr};`;
}

function compileBlock(body, returnsLast = false) {
  const parts = splitTopLevel(body);
  if (!parts.length) return "";
  return parts.map((p, i) => compileStatement(p, returnsLast && i === parts.length - 1 && !isControlStatement(p))).join("\n");
}

function isControlStatement(s) {
  return /^(let|fn|for|while|do|return|break|continue)\b/.test(s.trim()) || /^[A-Za-z_]\w*\s*=/.test(s.trim());
}

function compileFor(s) {
  const m = s.match(/^for\s+(.+?)\s+in\s+([\s\S]+?)\s*\{([\s\S]*)\}$/);
  if (!m) throw new Error(`bad for loop: ${s}`);
  const left = m[1].trim();
  const target = left.startsWith("[") ? left : `const ${left}`;
  return `for (${target} of ${compileExpr(m[2])}) { ${compileBlock(m[3])} }`;
}

function compileWhile(s) {
  const m = s.match(/^while\s+([\s\S]+?)\s*\{([\s\S]*)\}$/);
  if (!m) throw new Error(`bad while loop: ${s}`);
  return `while (${compileExpr(m[1])}) { ${compileBlock(m[2])} }`;
}

function compileDo(s) {
  const m = s.match(/^do\s*\{([\s\S]*)\}\s*(while|until)\s+([\s\S]*)$/);
  if (!m) throw new Error(`bad do loop: ${s}`);
  const cond = compileExpr(m[3]);
  return `do { ${compileBlock(m[1])} } while (${m[2] === "until" ? `!(${cond})` : cond});`;
}

function compileUse(s) {
  const m = s.match(/^use\s+([A-Za-z_]\w*)(?:\s*\{([^}]+)\})?/);
  if (!m) return "";
  if (!m[2]) return "";
  return `const { ${m[2].split(",").map((x) => x.trim()).filter(Boolean).join(", ")} } = ${m[1]};`;
}

function compileAssignment(s) {
  const idx = s.indexOf("=");
  return `${compileExpr(s.slice(0, idx).trim())} = ${compileExpr(s.slice(idx + 1))}`;
}

function params(text) {
  return text.split(",").map((p) => p.trim().replace(/^\.\.\./, "...")).filter(Boolean).join(", ");
}

function compileExpr(expr) {
  let s = expr.trim();
  s = unwrapOuter(s);
  if (s.startsWith("if ")) return compileIfExpr(s);
  if (s.startsWith("match ")) return compileMatchExpr(s);
  if (s.startsWith("try ")) return compileTryExpr(s);
  s = compilePipeline(s);
  s = convertStrings(s);
  s = convertMaps(s);
  s = convertRanges(s);
  s = convertKeywords(s);
  s = convertOperators(s);
  s = convertLambdas(s);
  s = convertOptional(s);
  return s;
}

function unwrapOuter(s) {
  if (s.startsWith("(") && matchingIndex(s, 0) === s.length - 1) return s.slice(1, -1).trim();
  return s;
}

function compileIfExpr(s) {
  const m = s.match(/^if\s+([\s\S]+?)\s*\{/);
  if (!m) throw new Error(`bad if: ${s}`);
  const cond = m[1];
  const thenStart = s.indexOf("{", m[0].length - 1);
  const thenEnd = matchingIndex(s, thenStart);
  const thenBody = s.slice(thenStart + 1, thenEnd);
  const rest = s.slice(thenEnd + 1).trim();
  const elseStart = rest.match(/^(else|el)\s*\{/);
  let elseBody = "undefined";
  if (elseStart) {
    const open = s.indexOf("{", thenEnd + 1);
    elseBody = s.slice(open + 1, matchingIndex(s, open));
  }
  return `(${compileExpr(cond)} ? (${compileBlockExpr(thenBody)}) : (${compileBlockExpr(elseBody)}))`;
}

function compileBlockExpr(body) {
  const parts = splitTopLevel(body);
  if (!parts.length) return "undefined";
  if (parts.length === 1 && !isControlStatement(parts[0])) return compileExpr(parts[0]);
  return `(() => { ${compileBlock(body, true)} })()`;
}

function compileMatchExpr(s) {
  const m = s.match(/^match\s+([\s\S]+?)\s*\{/);
  if (!m) throw new Error(`bad match: ${s}`);
  const value = compileExpr(m[1]);
  const open = s.indexOf("{", m[0].length - 1);
  const body = s.slice(open + 1, matchingIndex(s, open));
  const arms = splitMatchArms(body);
  let out = `__match(${value}, [`;
  out += arms.map((arm) => {
    const idx = arm.indexOf("=>");
    return `[${JSON.stringify(arm.slice(0, idx).trim())}, () => (${compileExpr(arm.slice(idx + 2))})]`;
  }).join(",");
  return `${out}])`;
}

function splitMatchArms(body) {
  const arms = [];
  let start = 0, depth = 0, quote = "", escape = false;
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (quote) {
      if (escape) escape = false; else if (c === "\\") escape = true; else if (c === quote) quote = "";
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if ("([{".includes(c)) depth++;
    else if (")]}".includes(c)) depth--;
    else if (c === "," && depth === 0) {
      const arm = body.slice(start, i).trim();
      if (arm) arms.push(arm);
      start = i + 1;
    }
  }
  const tail = body.slice(start).trim();
  if (tail) arms.push(tail);
  return arms;
}

function compileTryExpr(s) {
  const m = s.match(/^try\s*\{([\s\S]*)\}\s*catch\s+([A-Za-z_]\w*)\s*\{([\s\S]*)\}$/);
  if (!m) throw new Error(`bad try/catch: ${s}`);
  return `(() => { try { return ${compileBlockExpr(m[1])}; } catch (${m[2]}) { return ${compileBlockExpr(m[3])}; } })()`;
}

function compilePipeline(s) {
  const parts = splitByTopLevelOperator(s, "|>");
  if (parts.length <= 1) return s;
  let acc = compileExpr(parts[0]);
  for (const raw of parts.slice(1)) {
    const part = raw.trim();
    const call = part.match(/^([A-Za-z_][\w.]*)\s*\(([\s\S]*)\)$/);
    acc = call ? `${call[1]}(${[acc, call[2].trim()].filter(Boolean).join(", ")})` : `${part}(${acc})`;
  }
  return acc;
}

function convertMaps(s) {
  return s.replace(/(^|[=(:,\[\s])\{([A-Za-z_]\w*\s*:)/g, "$1({$2").replace(/\}([.\]\),;]|$)/g, "})$1");
}

function convertStrings(s) {
  return s.replace(/"([^"\\]*(?:\\.[^"\\]*)*)"/gs, (m, inner) => {
    if (!inner.includes("{")) return m;
    return "`" + inner.replace(/`/g, "\\`").replace(/\{([^}]+)\}/g, (_, e) => "${" + compileExpr(e) + "}") + "`";
  });
}

function convertRanges(s) {
  return s.replace(/(\b\d+|[A-Za-z_]\w*)\s*\.\.\s*(\b\d+|[A-Za-z_]\w*)/g, "__range($1,$2)");
}

function convertKeywords(s) {
  return s.replace(/\bnil\b/g, "null").replace(/\band\b/g, "&&").replace(/\bor\b/g, "||").replace(/\bnot\b/g, "!");
}

function convertOperators(s) {
  s = s.replace(/\+\+/g, "+");
  s = replaceTopLevelBinary(s, "**", (a, b) => `__pow(${a},${b})`);
  s = s.replace(/((?:"[^"]*"|'[^']*'|`[^`]*`|[A-Za-z_]\w*))\s*\*\s*(\d+)\b/g, "__mul($1,$2)");
  return s;
}

function convertLambdas(s) {
  return s.replace(/(\.\.\.)?([A-Za-z_]\w*)\s*=>\s*([^,\]\)]+)/g, "($1$2) => $3");
}

function convertOptional(s) {
  return s.replace(/\?\./g, "?.");
}

function replaceTopLevelBinary(s, op, fn) {
  const parts = splitByTopLevelOperator(s, op);
  if (parts.length <= 1) return s;
  return parts.map((p) => p.trim()).reduce((a, b) => fn(a, b));
}

function splitByTopLevelOperator(s, op) {
  const parts = [];
  let start = 0, depth = 0, quote = "", escape = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (quote) {
      if (escape) escape = false; else if (c === "\\") escape = true; else if (c === quote) quote = "";
      continue;
    }
    if (c === '"' || c === "'" || c === "`") { quote = c; continue; }
    if ("([{".includes(c)) depth++;
    else if (")]}".includes(c)) depth--;
    else if (depth === 0 && s.slice(i, i + op.length) === op) {
      parts.push(s.slice(start, i));
      start = i + op.length;
      i += op.length - 1;
    }
  }
  if (parts.length) parts.push(s.slice(start));
  return parts;
}

function matchingIndex(s, open) {
  const pairs = { "(": ")", "[": "]", "{": "}" };
  const close = pairs[s[open]];
  let depth = 0, quote = "", escape = false;
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (quote) {
      if (escape) escape = false; else if (c === "\\") escape = true; else if (c === quote) quote = "";
      continue;
    }
    if (c === '"' || c === "'" || c === "`") { quote = c; continue; }
    if (c === s[open]) depth++;
    else if (c === close && --depth === 0) return i;
  }
  return -1;
}

function builtins() {
  const b = {
    print: (...xs) => { console.log(...xs); return xs.at(-1); },
    len: (x) => x == null ? 0 : (typeof x === "object" && !Array.isArray(x) ? Object.keys(x).length : x.length),
    int: (x) => { const n = parseInt(x, 10); if (Number.isNaN(n)) throw new Error("bad int"); return n; },
    float: (x) => { const n = parseFloat(x); if (Number.isNaN(n)) throw new Error("bad float"); return n; },
    str: (x) => String(x),
    bool: (x) => Boolean(x),
    type_of: (x) => Array.isArray(x) ? "list" : x === null ? "nil" : typeof x === "object" ? "map" : typeof x === "number" && Number.isInteger(x) ? "int" : typeof x,
    trim: (s) => String(s).trim(),
    upper: (s) => String(s).toUpperCase(),
    lower: (s) => String(s).toLowerCase(),
    split: (s, sep) => String(s).split(sep),
    join: (xs, sep = "") => xs.join(sep),
    replace: (s, a, b) => String(s).split(a).join(b),
    contains: (x, y) => typeof x === "string" ? x.includes(y) : x.includes(y),
    starts: (s, p) => String(s).startsWith(p),
    ends: (s, p) => String(s).endsWith(p),
    repeat: (s, n) => String(s).repeat(n),
    chars: (s) => Array.from(String(s)),
    slice: (x, a, b) => x.slice(a, b),
    index_of: (s, sub) => String(s).indexOf(sub),
    ord: (s) => String(s).codePointAt(0),
    chr: (n) => String.fromCodePoint(n),
    char_at: (s, i) => Array.from(String(s))[i],
    map: (xs, f) => xs.map(f),
    filter: (xs, f) => xs.filter(f),
    reduce: (xs, f, init) => xs.reduce(f, init),
    fold: (xs, init, f) => xs.reduce(f, init),
    find: (xs, f) => xs.find(f),
    any: (xs, f) => xs.some(f),
    all: (xs, f) => xs.every(f),
    sort: (xs) => [...xs].sort((a, b) => a > b ? 1 : a < b ? -1 : 0),
    head: (xs) => xs[0],
    tail: (xs) => xs.slice(1),
    last: (xs) => xs.at(-1),
    reverse: (xs) => [...xs].reverse(),
    take: (xs, n) => xs.slice(0, n),
    drop: (xs, n) => xs.slice(n),
    flat: (xs) => xs.flat(Infinity),
    zip: (a, c) => a.map((x, i) => [x, c[i]]),
    enumerate: (xs) => xs.map((x, i) => [i, x]),
    push: (xs, x) => [...xs, x],
    concat: (a, c) => a.concat(c),
    sum: (xs) => xs.reduce((a, c) => a + c, 0),
    range: (a, c) => __range(a, c),
    keys: (m) => Object.keys(m),
    values: (m) => Object.values(m),
    entries: (m) => Object.entries(m).map(([key, value]) => ({ key, value })),
    abs: Math.abs,
    min: (...xs) => Array.isArray(xs[0]) ? Math.min(...xs[0]) : Math.min(...xs),
    max: (...xs) => Array.isArray(xs[0]) ? Math.max(...xs[0]) : Math.max(...xs),
    round: Math.round,
    assert: (cond, msg = "assertion failed") => { if (!cond) throw new Error(msg); return true; },
    time_ms: () => Date.now(),
    to_string: (x) => String(x),
  };
  b.math = { ...Math, PI: Math.PI, E: Math.E, pow: Math.pow, sqrt: Math.sqrt, ceil: Math.ceil, floor: Math.floor, clamp: (x, a, c) => Math.min(c, Math.max(a, x)) };
  b.strings = { pad_left: (s, n, c = " ") => String(s).padStart(n, c), pad_right: (s, n, c = " ") => String(s).padEnd(n, c), capitalize: (s) => String(s).charAt(0).toUpperCase() + String(s).slice(1), words: (s) => String(s).trim().split(/\s+/) };
  b.collections = { group_by: (xs, f) => xs.reduce((m, x) => ((m[f(x)] ??= []).push(x), m), {}), chunk: (xs, n) => Array.from({ length: Math.ceil(xs.length / n) }, (_, i) => xs.slice(i * n, i * n + n)), flatten: (xs) => xs.flat(Infinity), unique: (xs) => [...new Set(xs)] };
  b.json = { to_json: JSON.stringify, from_json: JSON.parse, pretty: (x) => JSON.stringify(x, null, 2), get_path: (o, path) => String(path).split(".").reduce((v, k) => v?.[k], o) };
  return b;
}

function runtimePrelude() {
  const keys = Object.keys(builtins());
  return `
const __range = (a,b) => Array.from({length: Math.max(0, b - a)}, (_, i) => a + i);
const __mul = (a,b) => typeof a === "string" ? a.repeat(b) : typeof b === "string" ? b.repeat(a) : a * b;
const __pow = (a,b) => a ** b;
const __match = (value, arms) => { for (const [pat, thunk] of arms) { if (pat === "_" || (pat.includes("..") ? value >= Number(pat.split("..")[0]) && value <= Number(pat.split("..")[1]) : value === Function("return (" + pat + ")")())) return thunk(); } };
const __builtins = (${builtins.toString()})();
const { ${keys.join(", ")} } = __builtins;
`;
}

module.exports = {
  lex,
  parse,
  createEnv,
  interpretWithEnv,
  generateIR,
  generateJS,
  format,
  lint,
  validateSource,
  validateToolCall,
  parseArcToml,
};
