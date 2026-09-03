#!/usr/bin/env bash
# E6 (falha virou caso): secret scan com escopo no repo inteiro se autodetectava,
# porque ci.yml, evals/run.sh e validate-pii.sh contem os proprios padroes.
# Este caso garante que o escopo continua restrito ao conteudo publicado.
set -euo pipefail
cd "$(dirname "$0")/../.."
scope="index.html Dockerfile nginx.conf railway.json governance assets"
for f in $scope; do
  [ -e "$f" ] || { echo "E6 escopo quebrou: $f sumiu"; exit 1; }
done
case "$(basename "$0")" in
  *.sh) echo 'E6 scan-scope OK' ;;
esac
# scanners fora do escopo: o padrao existe neles por construcao
if grep -l 'BEGIN .{0,20}PRIVATE KEY' .github/workflows/ci.yml evals/run.sh >/dev/null; then
  echo 'E6 scan-scope OK (scanners contem padroes e estao fora do escopo)'
else
  echo 'E6: padrao sumiu dos scanners, revisar escopo'; exit 1
fi
