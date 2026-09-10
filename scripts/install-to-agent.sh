#!/usr/bin/env bash
set -euo pipefail

# Instala as skills deste repositório no diretório de trabalho atual,
# adaptadas ao formato esperado pelo agente escolhido.
#
# Uso: install-to-agent.sh <agent>
#   agent: claude | cursor | codex | antigravity
#
# Rode isto de dentro do repositório de destino (o que vai *usar* as skills).

AGENT="${1:-}"
SKILLS_REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$(pwd)"

if [ -z "$AGENT" ]; then
  cat >&2 <<EOF
uso: install-to-agent.sh <agent>

agentes:
  claude       cria links simbólicos das skills em .claude/skills/ (projeto) ou ~/.claude/skills (usuário)
  cursor       gera arquivos .cursor/rules/<name>.mdc a partir de cada SKILL.md
  codex        adiciona um bloco "## Skills" ao AGENTS.md com resumos das skills
  antigravity  gera arquivos .antigravity/skills/<name>.md

Rode isto a partir do repositório de destino, não do repositório de skills.
EOF
  exit 1
fi

if [ "$TARGET" = "$SKILLS_REPO" ]; then
  echo "erro: rode isto a partir do repositório de destino, não do repositório de skills." >&2
  exit 1
fi

skill_dirs() {
  find "$SKILLS_REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0 |
    xargs -0 -n1 dirname
}

# Remove o frontmatter YAML de um SKILL.md, retornando o corpo.
skill_body() {
  awk 'BEGIN{f=0} /^---$/{f++; next} f>=2{print}' "$1"
}

# Lê um campo do frontmatter. Uso: fm <arquivo> <campo>
fm() {
  awk -v key="$2" '
    BEGIN{f=0}
    /^---$/{f++; if(f==2)exit; next}
    f==1 {
      if (match($0, "^"key":[[:space:]]*")) {
        print substr($0, RSTART+RLENGTH)
        exit
      }
    }
  ' "$1"
}

case "$AGENT" in
  claude)
    DEST="$TARGET/.claude/skills"
    mkdir -p "$DEST"
    skill_dirs | while IFS= read -r src; do
      name="$(basename "$src")"
      target="$DEST/$name"
      [ -e "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
      ln -sfn "$src" "$target"
      echo "link criado: $name -> $src"
    done
    ;;

  cursor)
    DEST="$TARGET/.cursor/rules"
    mkdir -p "$DEST"
    skill_dirs | while IFS= read -r src; do
      name="$(basename "$src")"
      desc="$(fm "$src/SKILL.md" description)"
      out="$DEST/${name}.mdc"
      {
        echo "---"
        echo "description: ${desc}"
        echo "alwaysApply: false"
        echo "---"
        echo
        skill_body "$src/SKILL.md"
      } > "$out"
      echo "escrito: $out"
    done
    echo
    echo "Regras do Cursor escritas. São regras 'manuais' — invoque com @<skill-name>."
    ;;

  codex)
    OUT="$TARGET/AGENTS.md"
    BLOCK_START="<!-- skills:start -->"
    BLOCK_END="<!-- skills:end -->"

    tmp_block="$(mktemp)"
    {
      echo "$BLOCK_START"
      echo "## Skills (skills)"
      echo
      echo "Instaladas de https://github.com/geraldobl58/skills. Cada entrada é um fluxo de trabalho que você invoca lendo o arquivo linkado e seguindo os passos dele."
      echo
      skill_dirs | while IFS= read -r src; do
        name="$(basename "$src")"
        desc="$(fm "$src/SKILL.md" description)"
        rel=".codex/skills/${name}/SKILL.md"
        echo "- **${name}** — ${desc}"
        echo "  - Workflow: \`${rel}\`"
      done
      echo
      echo "$BLOCK_END"
    } > "$tmp_block"

    # Espelha os corpos das skills em .codex/skills/ para o Codex ler.
    mkdir -p "$TARGET/.codex/skills"
    skill_dirs | while IFS= read -r src; do
      name="$(basename "$src")"
      cp -R "$src/." "$TARGET/.codex/skills/$name/"
    done

    if [ -f "$OUT" ] && grep -q "$BLOCK_START" "$OUT"; then
      awk -v start="$BLOCK_START" -v end="$BLOCK_END" -v repl="$tmp_block" '
        BEGIN { while ((getline line < repl) > 0) buf = buf line "\n" }
        $0 ~ start { skip=1; printf "%s", buf; next }
        $0 ~ end { skip=0; next }
        !skip { print }
      ' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
    else
      [ -f "$OUT" ] && echo >> "$OUT"
      cat "$tmp_block" >> "$OUT"
    fi
    rm "$tmp_block"
    echo "$OUT atualizado e skills copiadas para .codex/skills/"
    ;;

  antigravity)
    DEST="$TARGET/.antigravity/skills"
    mkdir -p "$DEST"
    skill_dirs | while IFS= read -r src; do
      name="$(basename "$src")"
      cp -R "$src/." "$DEST/$name/"
      echo "copiado: $name -> $DEST/$name"
    done
    ;;

  *)
    echo "agente desconhecido: $AGENT" >&2
    exit 1
    ;;
esac