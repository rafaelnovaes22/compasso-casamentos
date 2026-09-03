# Evals smoke

`run.sh` executa 5 casos (E1-E5), espelho dos jobs do CI. Uso: `bash evals/run.sh`.

## Falha vira caso

Toda falha encontrada em smoke manual ou producao vira caso permanente:

1. Criar `evals/cases.d/<slug>.sh` (exit 0 = pass, exit != 0 = fail).
2. Registrar a entrada em `cases.json` com o `mirrors_ci` correspondente.
3. O `run.sh` executa `cases.d/` automaticamente; o CI bloqueia merge enquanto vermelho.
