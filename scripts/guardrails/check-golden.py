#!/usr/bin/env python3
"""PORQUE (C2/C4): golden anti-alucinacao. Score <=94%% => BLOQUEADO POR ALUCINACAO (exit 2)."""
import json, re, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GOLD = os.path.join(ROOT, "evals", "guardrails", "golden.json")
LOG = os.path.join(ROOT, "evals", "guardrails", "golden-log.json")

def main():
    gold = json.load(open(GOLD, encoding="utf-8"))
    html = open(os.path.join(ROOT, "index.html"), encoding="utf-8", errors="ignore").read()
    low = html.lower()
    total = len(gold["cases"])
    hits = 0
    details = []
    for c in gold["cases"]:
        kind = c.get("check", "contains")
        if kind == "contains":
            ok = c["expect"].lower() in low
        elif kind == "absent":
            ok = c["expect"].lower() not in low
        elif kind == "regex":
            ok = re.search(c["expect"], html, re.I | re.S) is not None
        elif kind == "absent_regex":
            ok = re.search(c["expect"], html, re.I | re.S) is None
        else:
            ok = False
        hits += 1 if ok else 0
        details.append({"id": c["id"], "ok": ok, "name": c.get("name", "")})
    score = round(100.0 * hits / total, 1) if total else 0.0
    json.dump({"score": score, "hits": hits, "total": total, "details": details}, open(LOG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"golden: {hits}/{total} = {score}% (log: evals/guardrails/golden-log.json)")
    if score <= 94:
        print(f"BLOQUEADO POR ALUCINACAO: score {score}% <= 94%")
        sys.exit(2)
    sys.exit(0 if fails0(details) else 1)

def fails0(details):
    return all(d["ok"] for d in details)

if __name__ == "__main__":
    main()
