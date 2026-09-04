#!/usr/bin/env python3
"""PORQUE (C3): custo SLM. >=25%% => BLOQUEADO POR CUSTO (exit 3). Site estatico: sem LLM backend, custo LLM 0%%."""
import json, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
COST = os.path.join(ROOT, "evals", "guardrails", "cost.json")
LOG = os.path.join(ROOT, "evals", "guardrails", "cost-log.json")

def main():
    data = json.load(open(COST, encoding="utf-8"))
    ratio = float(data["cost_ratio_pct"])
    json.dump({"cost_ratio_pct": ratio, "model": data.get("model"), "notes": data.get("notes")}, open(LOG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"custo: {ratio}% do preco (modelo: {data.get('model')})")
    if ratio >= 25:
        print(f"BLOQUEADO POR CUSTO: {ratio}% >= 25%")
        sys.exit(3)
    sys.exit(0)

if __name__ == "__main__":
    main()
