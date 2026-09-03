#!/usr/bin/env bash
# PORQUE: dado pessoal em codigo sem inventario e nao conformidade (ISO 42001 A.7.2).
# Adaptado de ai-governance-kit validate-suppliers.ts. Contato publico (wa.me/mailto)
# precisa estar declarado no inventario; segredo tecnico reprova.
set -euo pipefail
cd "$(dirname "$0")/../.."
inv="governance/data/inventory.yaml"
test -f "$inv" || { echo "FAIL: $inv ausente"; exit 1; }
python3 - "$inv" <<'EOF'
import re, sys
html = open('index.html', encoding='utf-8', errors='ignore').read()
inv = open(sys.argv[1], encoding='utf-8').read()
secret_pats = [r'AKIA[0-9A-Z]{16}', r'ghp_[A-Za-z0-9]{10,}', r'BEGIN .{0,20}PRIVATE KEY',
               r'sk-live-[A-Za-z0-9]+', r'xoxb-[A-Za-z0-9-]+', r'\d{3}\.\d{3}\.\d{3}-\d{2}']
for pat in secret_pats:
    m = re.search(pat, html)
    assert not m, 'PII/segredo em index.html: ' + pat
declared = inv.split('contacts:')[1] if 'contacts:' in inv else ''
for num in set(re.findall(r'wa\.me/(\d+)', html)):
    assert num in declared, 'wa.me/' + num + ' nao declarado em inventory.yaml contacts'
for mail in set(re.findall(r'mailto:([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})', html)):
    assert mail in declared, 'mailto:' + mail + ' nao declarado em inventory.yaml contacts'
print('PII OK: sem segredo em codigo, contatos publicos inventariados')
EOF
