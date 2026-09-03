#!/usr/bin/env bash
# PORQUE: risco com level errado ou controle para arquivo inexistente e ficcao.
# Adaptado de ai-governance-kit validate-risk-register.ts (ISO 42001 6.1). Zero deps alem de python3.
set -euo pipefail
cd "$(dirname "$0")/../.."
reg="governance/risk/risk-register.yaml"
test -f "$reg" || { echo "FAIL: $reg ausente"; exit 1; }
python3 - "$reg" <<'EOF'
import re, os, sys
text = open(sys.argv[1], encoding='utf-8').read()
blocks = re.split(r'(?m)^\s*-\s+id:\s*', text)[1:]
assert blocks, 'nenhum risco declarado'
def level(p, i): return p * i
def classification(v): return 'baixo' if v <= 4 else 'medio' if v <= 9 else 'alto' if v <= 14 else 'critico'
for b in blocks:
    rid = b.split('\n', 1)[0].strip()
    get = lambda k: re.search(r'(?m)^\s*' + k + r':\s*(.+?)\s*$', b)
    p = int(get('probability').group(1)); i = int(get('impact').group(1))
    lv = int(get('level').group(1)); cl = get('classification').group(1).strip()
    assert lv == level(p, i), rid + ': level ' + str(lv) + ' != probability x impact (' + str(level(p, i)) + ')'
    assert cl == classification(lv), rid + ': classificacao ' + cl + ' != ' + classification(lv)
    ctrls = re.findall(r'(?m)^\s*-\s+(\S.*\S)\s*$', b.split('controls:')[1] if 'controls:' in b else '')
    assert ctrls, rid + ': sem controles'
    for c in ctrls:
        assert os.path.exists(c), rid + ': controle aponta para arquivo inexistente: ' + c
print('risco OK: ' + str(len(blocks)) + ' riscos, controles ancorados em arquivo real')
EOF
