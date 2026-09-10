#!/usr/bin/env bash
set -euo pipefail

# Trava de testes: falha quando um arquivo de código alterado não tem teste.
#
# Uso:
#   check-test-pairs.sh [--base <ref>] [--all] [--quiet]
#
#   (sem flags)    mudanças da árvore de trabalho (modificados + novos)
#   --base <ref>   o que mudou em relação a <ref> (ex.: --base origin/main)
#   --all          todos os arquivos versionados
#   --quiet        imprime só o resumo
#
# Saída: 0 = coberto, 2 = falta teste (bloqueia o hook), 1 = erro de uso.
#
# Isenção deliberada: um arquivo é ignorado se tiver, nas 10 primeiras linhas,
# um comentário com `test-ignore: <motivo>`. Assim a exceção fica no código,
# visível em review, em vez de escondida no script.
#
# Ajuste por variável de ambiente (regex estendida):
#   SRC_ROOT_RE  diretórios que exigem teste
#   EXEMPT_RE    caminhos isentos

usage() {
  cat <<'EOF'
uso: check-test-pairs.sh [--base <ref>] [--all] [--quiet]

  (sem flags)    verifica as mudanças da árvore de trabalho
  --base <ref>   verifica o que mudou em relação a <ref>
  --all          verifica todos os arquivos versionados
  --quiet        imprime só o resumo

Saída: 0 = tudo coberto, 2 = falta teste, 1 = erro de uso ou ref inválida.

Exemplo em CI:
  ./check-test-pairs.sh --base origin/main

Em CI, garanta histórico suficiente (fetch-depth: 0): com clone raso o
merge-base não é calculável e o script falha com exit 1 de propósito.
EOF
}

MODE="worktree"
BASE=""
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --base)
      if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
        echo "erro: --base exige uma ref (ex.: --base origin/main)" >&2
        exit 1
      fi
      MODE="base"
      BASE="$2"
      shift 2
      ;;
    --all)
      MODE="all"
      shift
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "erro: argumento desconhecido: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  echo "check-test-pairs: não é um repositório git — nada a verificar" >&2
  exit 0
fi
cd "$ROOT"

# Sem um merge-base calculável, a verificação não verifica nada. Falhar em
# silêncio aqui seria pior do que não ter trava: o CI passaria verde sem olhar
# arquivo nenhum (acontece com checkout raso, fetch-depth: 1).
MERGE_BASE=""
if [ "$MODE" = "base" ]; then
  MERGE_BASE="$(git merge-base "$BASE" HEAD 2>/dev/null || true)"
  if [ -z "$MERGE_BASE" ]; then
    echo "check-test-pairs: erro: não consegui calcular o merge-base entre '$BASE' e HEAD." >&2
    echo "Verifique se a ref existe e se o clone tem histórico suficiente (fetch-depth: 0)." >&2
    echo "Nada foi verificado — falhando por segurança." >&2
    exit 1
  fi
fi

# Diretórios que exigem teste. Cobre os layouts comuns de front e de back.
SRC_ROOT_RE="${SRC_ROOT_RE:-^(src|app|apps|packages|lib|libs|server|backend|frontend|services|internal|cmd|api|domain|application|infra)/}"

# Isentos por caminho: o próprio teste, tipos, enums, constantes, mocks,
# migrações, seeds, fixtures, gerados, configuração, stories.
EXEMPT_RE="${EXEMPT_RE:-\.test\.|\.spec\.|_test\.|/test_|^test_|/__tests__/|/__mocks__/|/types/|/interfaces/|/enums/|/constants/|/migrations/|/seeds/|/fixtures/|/generated/|/dist/|/build/|/coverage/|\.d\.ts$|\.config\.|\.stories\.|\.gen\.|\.g\.|/i18n/|/mocks/|/locales/}"

CODE_RE='\.(ts|tsx|js|jsx|mjs|cjs|go|py|rb|php|java|kt|kts|cs|rs|swift)$'

# --- listagem dos arquivos candidatos ------------------------------------

list_files() {
  case "$MODE" in
    worktree)
      # -uall para listar arquivo a arquivo em vez de só o diretório novo.
      git status --porcelain --untracked-files=all | awk '{print $NF}'
      ;;
    base)
      git diff --name-only --diff-filter=ACMR "$MERGE_BASE" HEAD
      ;;
    all)
      git ls-files
      ;;
  esac
}

matches() {
  # matches <texto> <regex>
  printf '%s' "$1" | grep -Eq "$2"
}

# --- existe teste para este arquivo? -------------------------------------

has_test() {
  local f="$1" dir stem ext rel rdir c
  dir="$(dirname "$f")"
  stem="$(basename "${f%.*}")"
  ext="${f##*.}"
  rel="${f#*/}"                       # src/features/a/b.ts -> features/a/b.ts
  rdir="$(dirname "$rel")"

  local candidates=(
    # irmão no mesmo diretório
    "$dir/$stem.test.$ext" "$dir/$stem.test.ts" "$dir/$stem.test.tsx"
    "$dir/$stem.test.js" "$dir/$stem.test.jsx"
    "$dir/$stem.spec.$ext" "$dir/$stem.spec.ts" "$dir/$stem.spec.tsx"
    # convenções de outras linguagens, mesmo diretório
    "$dir/${stem}_test.go" "$dir/${stem}_test.py" "$dir/test_${stem}.py"
    "$dir/${stem}Test.java" "$dir/${stem}Test.kt" "$dir/${stem}Tests.cs"
    "$dir/${stem}_spec.rb" "$dir/${stem}_test.rb"
    # subpasta de testes
    "$dir/__tests__/$stem.test.$ext" "$dir/__tests__/$stem.test.ts"
    "$dir/__tests__/$stem.test.tsx" "$dir/__tests__/$stem.spec.$ext"
    "$dir/tests/$stem.test.$ext"
    # espelho em tests/ na raiz
    "$ROOT/tests/$rel"
    "$ROOT/tests/$rdir/$stem.test.$ext" "$ROOT/tests/$rdir/$stem.test.ts"
    "$ROOT/tests/$rdir/$stem.test.tsx" "$ROOT/tests/$rdir/${stem}_test.go"
    "$ROOT/tests/$rdir/test_${stem}.py" "$ROOT/test/$rdir/$stem.test.$ext"
  )

  for c in "${candidates[@]}"; do
    if [ -e "$c" ]; then
      return 0
    fi
  done
  return 1
}

# --- verificação ---------------------------------------------------------

missing=()
checked=0

while IFS= read -r f; do
  if [ -z "$f" ]; then
    continue
  fi
  if [ ! -f "$f" ]; then
    continue
  fi
  if ! matches "$f" "$CODE_RE"; then
    continue
  fi
  if ! matches "$f" "$SRC_ROOT_RE"; then
    continue
  fi
  if matches "$f" "$EXEMPT_RE"; then
    continue
  fi
  if head -10 "$f" | grep -qE 'test-ignore:'; then
    continue
  fi

  checked=$((checked + 1))
  if ! has_test "$f"; then
    missing+=("$f")
  fi
done < <(list_files | sort -u)

if [ "${#missing[@]}" -eq 0 ]; then
  if [ "$QUIET" -eq 0 ]; then
    echo "check-test-pairs: ✅ $checked arquivo(s) de código verificados, todos com teste."
  fi
  exit 0
fi

# Convenção de nome do teste, por linguagem, só para a dica na mensagem.
expected_hint() {
  local f="$1" stem ext
  stem="$(basename "${f%.*}")"
  ext="${f##*.}"
  case "$ext" in
    go) echo "$(dirname "$f")/${stem}_test.go" ;;
    py) echo "$(dirname "$f")/test_${stem}.py" ;;
    java|kt|kts) echo "$(dirname "$f")/${stem}Test.$ext" ;;
    cs) echo "$(dirname "$f")/${stem}Tests.cs" ;;
    rb) echo "$(dirname "$f")/${stem}_spec.rb" ;;
    *) echo "$(dirname "$f")/${stem}.test.$ext" ;;
  esac
}

{
  echo "check-test-pairs: ❌ ${#missing[@]} de $checked arquivo(s) de código sem teste:"
  echo
  for f in "${missing[@]}"; do
    echo "  $f"
    echo "      esperado: $(expected_hint "$f")  (ou __tests__/ equivalente)"
  done
  echo
  echo "Escreva o teste do comportamento antes de dar a entrega por concluída."
  echo "Se o arquivo for isento de propósito, adicione nas primeiras linhas:"
  echo "    test-ignore: <motivo>"
} >&2

exit 2
