#!/usr/bin/env bash
# PORQUE: inventario que nao reflete o disco vira decoracao (ai-governance-kit).
# Todo arquivo listado precisa existir; index.html e assets/ precisam estar listados.
set -euo pipefail
cd "$(dirname "$0")/../.."
inv="governance/data/inventory.yaml"
test -f "$inv" || { echo "FAIL: $inv ausente"; exit 1; }
python3 - "$inv" <<'EOF'
import re, os, sys
inv = open(sys.argv[1], encoding='utf-8').read()
files = re.findall(r'(?m)^\s*-\s+(\S.*\S)\s*$', inv.split('files:')[1].split('contacts:')[0])
assert files, 'inventory sem files'
for f in files:
    assert os.path.exists(f), 'inventariado mas inexistente: ' + f
names = ' '.join(files)
assert 'index.html' in names, 'index.html fora do inventario'
if os.path.isdir('assets'):
    assert 'assets/' in names, 'assets/ existe no disco mas fora do inventario'
print('dados OK: ' + str(len(files)) + ' entradas, todas existem no disco')
EOF
