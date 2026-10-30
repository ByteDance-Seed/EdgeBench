from __future__ import annotations

from typing import Dict, Iterable, List, Sequence


def _to_int_labels(seq: Iterable[int | str]) -> List[int]:
    out: List[int] = []
    for x in seq:
        try:
            out.append(int(x))
        except Exception:
            continue
    return out


def _f1_for_label(y_true: Sequence[int], y_pred: Sequence[int], label: int) -> float:
    tp = fp = fn = 0
    for t, p in zip(y_true, y_pred):
        if p == label and t == label:
            tp += 1
        elif p == label and t != label:
            fp += 1
        elif p != label and t == label:
            fn += 1
    den = 2 * tp + fp + fn
    return (2.0 * tp / den) if den > 0 else 0.0


def _micro_f1(y_true: Sequence[int], y_pred: Sequence[int]) -> float:
    # single-label multiclass micro-f1 equals accuracy under one-vs-rest aggregation
    if not y_true:
        return 0.0
    correct = sum(1 for t, p in zip(y_true, y_pred) if t == p)
    return float(correct) / float(len(y_true))


def _macro_f1(y_true: Sequence[int], y_pred: Sequence[int]) -> float:
    labels = sorted(set(y_true) | set(y_pred))
    if not labels:
        return 0.0
    vals = [_f1_for_label(y_true, y_pred, lb) for lb in labels]
    return float(sum(vals)) / float(len(vals))


def _balanced_accuracy(y_true: Sequence[int], y_pred: Sequence[int]) -> float:
    labels = sorted(set(y_true))
    if not labels:
        return 0.0
    recalls: List[float] = []
    for lb in labels:
        tp = fn = 0
        for t, p in zip(y_true, y_pred):
            if t == lb and p == lb:
                tp += 1
            elif t == lb and p != lb:
                fn += 1
        den = tp + fn
        recalls.append((float(tp) / float(den)) if den > 0 else 0.0)
    return float(sum(recalls)) / float(len(recalls))


def _ece(y_true: Sequence[int], y_pred: Sequence[int], confidences: Sequence[float] | None = None, n_bins: int = 10) -> float:
    if not y_true:
        return 1.0
    confs = list(confidences) if confidences is not None else [1.0] * len(y_true)
    confs = [min(1.0, max(0.0, float(c))) for c in confs]

    bins = [[] for _ in range(n_bins)]
    for i, (t, p, c) in enumerate(zip(y_true, y_pred, confs)):
        b = min(n_bins - 1, int(c * n_bins))
        bins[b].append((t, p, c, i))

    total = float(len(y_true))
    ece = 0.0
    for b in bins:
        if not b:
            continue
        acc = sum(1.0 for t, p, _, _ in b if t == p) / float(len(b))
        conf = sum(c for _, _, c, _ in b) / float(len(b))
        ece += abs(acc - conf) * (float(len(b)) / total)
    return ece


def evaluate(
    predictions: Dict[str, int | str],
    ground_truth: Dict[str, int | str],
    confidences: Dict[str, float] | None = None,
) -> Dict[str, float]:
    ordered_ids = [nid for nid in ground_truth.keys() if nid in predictions]
    y_true = _to_int_labels(ground_truth[nid] for nid in ordered_ids)
    y_pred = _to_int_labels(predictions[nid] for nid in ordered_ids)

    # align lengths in case conversion dropped labels
    n = min(len(y_true), len(y_pred))
    y_true = y_true[:n]
    y_pred = y_pred[:n]

    conf_arr = None
    if confidences is not None:
        conf_arr = [float(confidences.get(nid, 1.0)) for nid in ordered_ids[:n]]

    micro_f1 = _micro_f1(y_true, y_pred)
    macro_f1 = _macro_f1(y_true, y_pred)
    balanced_acc = _balanced_accuracy(y_true, y_pred)
    ece = _ece(y_true, y_pred, conf_arr)

    return {
        "micro_f1": micro_f1,
        "macro_f1": macro_f1,
        "balanced_accuracy": balanced_acc,
        "ece": ece,
        "one_minus_ece": max(0.0, 1.0 - ece),
    }
