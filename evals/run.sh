#!/usr/bin/env bash
# PORQUE: evals smoke local, espelho do CI. Falha aqui bloqueia merge e deploy.
# Falha nova vira caso: adicionar script em evals/cases.d/ (ver evals/README.md).
set -euo pipefail
cd "$(dirname "$0")/.."
pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1 :: $2"; }

# E1 index: titulo nao vazio e tamanho minimo
if python3 -c "import re,sys;t=open('index.html',encoding='utf-8',errors='ignore').read();sys.exit(0 if (re.search(r'<title>[^<]*[^ <][^<]*</title>',t) and len(t)>5000) else 1)"; then ok E1-index; else bad E1-index 'titulo ausente ou pagina < 5KB'; fi

# E2 docker: builda e serve 200 (porta via EVAL_PORT p/ gates paralelos)
if docker build -q -t site:eval . >/dev/null; then
  id=$(docker run -d -p "${EVAL_PORT:-18080}":8080 site:eval)
  trap 'docker rm -f "$id" >/dev/null 2>&1' EXIT
  ok_body=0
  for _ in $(seq 1 15); do curl -fsS http://localhost:"${EVAL_PORT:-18080}"/ >/dev/null 2>&1 && { ok_body=1; break; }; sleep 2; done
  docker rm -f "$id" >/dev/null 2>&1; trap - EXIT
  if [ "$ok_body" = 1 ]; then ok E2-docker-serve; else bad E2-docker-serve 'container nao serviu 200'; fi
else bad E2-docker-serve 'docker build falhou'; fi

# E3 links: mesmos criterios do CI
if python3 - <<'EOF'; then ok E3-links; else bad E3-links 'ver job smoke-links do CI'; fi
import re, sys
t = open('index.html', encoding='utf-8', errors='ignore').read()
hrefs = re.findall(r'href="([^"]*)"', t)
ids = set(re.findall(r'id="([^"]+)"', t))
bad = []
for h in hrefs:
    if not h.strip(): bad.append('(href vazio)')
    elif h.startswith('#'):
        if h != '#' and h[1:] not in ids: bad.append(h)
    elif any(c in h for c in ("'", '+', '{', '}')): continue
    elif not re.match(r'(https?://|mailto:|tel:)', h): bad.append(h)
if bad: print(bad); sys.exit(1)
EOF

# E4 form: semantica ou N/A documentado
if python3 - <<'EOF'; then ok E4-form; else bad E4-form 'ver job smoke-form do CI'; fi
import re, sys
t = open('index.html', encoding='utf-8', errors='ignore').read()
forms = re.findall(r'<form[^>]*>(.*?)</form>', t, re.I | re.S)
if not forms: sys.exit(0)
for f in forms:
    assert re.search(r'(type="submit"|<button|required)', f, re.I)
    assert re.search(r'(<label|aria-label|placeholder=)', f, re.I)
EOF

# E5 secrets: conteudo publicado (scanners excluidos: eles contem os proprios padroes)
if grep -rEn -e 'AKIA[0-9A-Z]{16}' -e 'ghp_[A-Za-z0-9]{10,}' -e 'BEGIN .{0,20}PRIVATE KEY' -e 'sk-live-[A-Za-z0-9]+' -e 'xoxb-[A-Za-z0-9-]+' index.html Dockerfile nginx.conf railway.json governance assets 2>/dev/null; then bad E5-secrets 'padrao de segredo encontrado'; else ok E5-secrets; fi

# Casos extras registrados via "falha vira caso"
if [ -d evals/cases.d ]; then
  for c in evals/cases.d/*.sh; do
    [ -e "$c" ] || continue
    if bash "$c"; then ok "extra-$(basename "$c")"; else bad "extra-$(basename "$c")" 'ver script do caso'; fi
  done
fi

echo "evals: $pass pass, $fail fail"
[ "$fail" = 0 ]
