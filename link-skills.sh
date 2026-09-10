#!/usr/bin/env bash
set -euo pipefail

# Cria links simbólicos de todas as pastas com SKILL.md deste repositório
# em ~/.claude/skills, para o Claude Code carregá-las como skills de usuário.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.claude/skills"

if [ -L "$DEST" ]; then
  resolved="$(readlink -f "$DEST" 2>/dev/null || readlink "$DEST")"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      echo "erro: $DEST é um link simbólico para dentro deste repositório ($resolved)." >&2
      echo "Remova-o (rm \"$DEST\") e rode de novo." >&2
      exit 1
      ;;
  esac
fi

mkdir -p "$DEST"

find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0 |
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  target="$DEST/$name"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    rm -rf "$target"
  fi

  ln -sfn "$src" "$target"
  echo "link criado: $name -> $src"
done