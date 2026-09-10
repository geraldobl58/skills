---
name: spec-impl
description: Implementa uma spec aprovada. Valida que o estado significa "Aprovado" (em qualquer idioma), cria uma branch git com o nome da spec, muda para ela e começa a implementação passo a passo com pausas para revisar os diffs.
disable-model-invocation: true
argument-hint: <NN-nome-da-spec>
allowed-tools: Read, Glob, Grep, Edit, Write, AskUserQuestion, Bash(git status:*), Bash(git branch:*), Bash(git checkout:*), Bash(git log:*), Bash(git diff:*), Bash(git stash:*), Bash(cat:*), Bash(ls:*)
---

# /spec-impl — Implementador de specs aprovadas

## Contexto da sessão

Estado atual do repositório:
!`git status --short`

Branch atual:
!`git branch --show-current`

Specs disponíveis nesta pasta:
!`ls specs/ 2>/dev/null || echo "A pasta specs/ não existe"`

Configuração de criação de branch:
!`cat specs/.spec-config.yml 2>/dev/null || echo "AutoCreateBranch: true (padrão, sem arquivo de configuração)"`

---

## Instruções

Siga estas quatro fases em ordem estrita. **Não avance para a próxima fase se a anterior não tiver sido concluída corretamente.**

> **Invocação explícita.** Esta skill só roda quando o usuário a chama (`/spec-impl <NN-slug>`). Ela cria branch e escreve código: nunca a inicie por conta própria, nem encadeie a implementação porque o usuário aprovou uma spec minutos antes. Em agentes que recebem apenas o corpo do `SKILL.md` (Cursor, Codex, Antigravity), o `disable-model-invocation` do frontmatter é descartado pelo instalador — a garantia que sobrevive é esta linha.

---

### Fase 1 — Identifique a spec

O argumento recebido é: `$ARGUMENTS`

Se `$ARGUMENTS` estiver vazio:

- Liste os arquivos disponíveis em `specs/` (você já os tem acima).
- Peça ao usuário o nome exato da spec.
- Pare e espere a resposta. Não continue.

Se `$ARGUMENTS` tiver um valor:

- Procure o arquivo em `specs/`. O usuário pode ter escrito o nome completo (`01-mvp-arkanoid`), apenas o número (`01`) ou apenas o slug (`mvp-arkanoid`). Tente encontrar o arquivo correto em qualquer um desses casos.
- Se não encontrar o arquivo, mostre as specs disponíveis e peça ao usuário para corrigir o nome.
- Se encontrar, siga para a Fase 2.

---

### Fase 2 — Valide o estado da spec

Leia o arquivo da spec que você localizou na Fase 1 com a ferramenta Read ou com `cat`.

No conteúdo do arquivo, procure a linha que contém o estado da spec. O rótulo do cabeçalho normalmente é `**Status:**` ou `**Estado:**`, mas pode estar em qualquer idioma. Reconheça pela posição (linha de estado no topo da spec) e pela máquina de estados ao redor, não pelo rótulo exato.

**Regra absoluta:** você só pode continuar se o estado **significar "Aprovado"** — independentemente do idioma usado.

Trate qualquer um dos seguintes (e seus equivalentes em outros idiomas) como o estado **Aprovado** e continue:

- Português: `Aprovado`
- Inglês: `Approved`
- Espanhol: `Aprobado`
- Francês: `Approuvé`
- Alemão: `Genehmigt`
- Italiano: `Approvato`
- …ou a palavra de qualquer outro idioma que claramente signifique "aprovado"

Qualquer outra coisa (Rascunho / Draft, Em revisão / In review, Implementado / Implemented, Obsoleto / Obsolete, ou qualquer valor não reconhecido) significa **parar** e mostrar a mensagem de erro abaixo.

| Categoria de estado                             | Exemplos (qualquer idioma)                        | Ação                                                                |
| ----------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------- |
| Aprovado                                        | `Aprovado`, `Approved`, `Aprobado`, `Approuvé`, … | Continue para a Fase 3.                                             |
| Rascunho                                        | `Rascunho`, `Draft`, `Borrador`, …                | Pare. Mostre a mensagem de erro abaixo.                             |
| Em revisão                                      | `Em revisão`, `In review`, `En revisión`, …       | Pare. Mostre a mensagem de erro abaixo.                             |
| Implementado                                    | `Implementado`, `Implemented`, …                  | Pare. Mostre a mensagem de erro abaixo.                             |
| Obsoleto                                        | `Obsoleto`, `Obsolete`, …                         | Pare. Mostre a mensagem de erro abaixo.                             |
| Linha de estado ausente / valor não reconhecido | —                                                 | Pare. O arquivo não segue o formato esperado. Diga isso ao usuário. |

Se você não tiver certeza se um valor significa "aprovado", **não suponha**. Pare e peça ao usuário para clarificar ou atualizar a spec para a redação canônica.

**Mensagem de erro padrão quando o estado não significa Aprovado:**

```
❌ Não posso implementar esta spec.

Estado atual: [ESTADO ENCONTRADO]
Eu só trabalho com specs cujo estado significa "Aprovado" (ex.: `Aprovado`,
`Approved`, ou o equivalente em outro idioma).

Para continuar você tem duas opções:
  1. Se a spec está pronta para ser implementada, abra e mude o estado
     para "Aprovado" (ou o termo equivalente que seu time usa) na mão.
     Essa mudança é feita pelo humano, não pelo agente.
  2. Se a spec ainda precisa de trabalho, use /spec [nome] para retomá-la.
```

Não ofereça alternativas, não sugira "posso começar mesmo assim se você quiser". O bloqueio é intencional.

---

### Fase 3 — Crie a branch git e mude para ela

Depois de confirmar que o estado significa `Aprovado`:

0. **Verifique a árvore de trabalho primeiro.** Olhe a saída de `git status --short` no contexto da sessão acima. Se ela **não estiver vazia**, pare e mostre as mudanças pendentes, depois pergunte:

   ```
   ⚠️ Existem mudanças não commitadas na árvore de trabalho.
   Mudar de branch as levaria junto. O que você quer fazer?
     1. Commitar ou dar stash você mesmo, e rodar este comando de novo  (recomendado)
     2. Continuar mesmo assim — as mudanças vão para a nova branch
   ```

   Espere a resposta. **Não faça stash nem commit no lugar do usuário** a menos que ele peça explicitamente. Se a árvore de trabalho está limpa, vá direto ao passo 1 sem mencionar isso.

1. Derive o nome da branch a partir do nome completo do arquivo da spec, sem a extensão. Formato: `spec-NN-slug`. Exemplos:
   - `01-mvp-arkanoid.md` → branch `spec-01-mvp-arkanoid`
   - `02-powerups.md` → branch `spec-02-powerups`

2. Leia a flag `AutoCreateBranch` da **Configuração de criação de branch** mostrada no contexto da sessão acima.
   - Se o arquivo de configuração não existe, o valor está ausente ou o valor não é reconhecido → trate como `true` (o padrão).
   - Só um `false` explícito (em qualquer capitalização) desativa a criação automática da branch.

   **Se `AutoCreateBranch` for `true` (padrão):** prossiga sem perguntar.
   - Se a branch **não existe**: crie com `git checkout -b spec-NN-slug`.
   - Se ela **já existe**: isso significa que um trabalho anterior está sendo retomado. Mude para ela, leia `git log --oneline` na branch, e diga ao usuário quais passos do plano já parecem feitos e de qual passo você propõe retomar. Espere a confirmação do ponto de retomada antes de implementar qualquer coisa.
   - Nos dois casos: mude para a branch com `git checkout spec-NN-slug` e confirme que a mudança deu certo antes de continuar.

   **Se `AutoCreateBranch` for `false`:** pergunte antes de mexer no git. Mostre:

   ```
   AutoCreateBranch está definido como false.
   Criar e mudar para a branch spec-NN-slug? [y/N]
   ```

   - Se o usuário responder **sim**: crie/mude para a branch exatamente como no caso `true` acima.
   - Se o usuário responder **não** ou deixar vazio: **não crie branch nenhuma.** Diga que você vai implementar na branch atual (a mostrada no contexto da sessão acima) e peça confirmação explícita para continuar nela. Não improvise — espere a resposta.

3. Confirme ao usuário, de forma visível, que a spec está pronta e qual branch está ativa:

   ```
   ✅ Pronto para implementar.

   Spec:   specs/NN-slug.md
   Branch: spec-NN-slug  (ativa)   (← ou a branch atual, se nenhuma nova foi criada)
   Estado: Aprovado   (← repita o valor real encontrado na spec)
   ```

4. **Não comece a implementar ainda.** Primeiro mostre o resumo da spec ao usuário, para ele ter tudo fresco. Extraia e mostre:
   - O **objetivo** (a linha depois de `**Objetivo:**` / `**Objective:**` / rótulo equivalente).
   - O **escopo** (a seção `## Escopo` / `## Scope` / equivalente).
   - O **plano de implementação** (a seção com os passos numerados — `## Plano de implementação` / `## Implementation plan` / equivalente).
   - Os **critérios de aceite** (o checklist — `## Critérios de aceite` / `## Acceptance criteria` / equivalente).

Reconheça os títulos das seções pelo significado, não pela redação exata — a spec pode estar escrita em qualquer idioma.

---

### Fase 4 — Implemente passo a passo

Depois de mostrar o resumo da spec, diga ao usuário:

```
Vou implementar a spec seguindo o plano de implementação exatamente.
Vou pausar depois de cada passo para você revisar o diff.

Começamos pelo Passo 1?
```

Espere uma confirmação explícita ("sim", "pode ir", "vai", ou equivalente). Não comece sem ela.

Depois da confirmação, siga estas regras durante toda a implementação:

**Nunca faça commit automaticamente.** Nem por passo, nem no final. Você escreve o código e mostra o diff; commitar é decisão e comando do usuário. Só faça commit se ele pedir explicitamente.

**Uma regra acima de tudo:** implemente o que a spec diz. Se algo na spec parecer subótimo para você, mencione como observação mas implemente o que foi acordado. Mudanças na spec vão para a spec, não para o código de surpresa.

**Ritmo de trabalho:**

- Implemente um passo do plano **com o teste** do comportamento que ele introduz — um passo sem teste não está concluído (ver a skill `unit-testing-standards`).
- Mostre um resumo de quais arquivos você tocou e o que fez.
- Diga: `Passo N concluído. Pode revisar o diff e me dizer se sigo para o Passo N+1?`
- Espere a confirmação antes de continuar.

**Se durante a implementação você encontrar uma ambiguidade** que a spec não resolve:

- Pare.
- Descreva a ambiguidade exatamente.
- Apresente duas ou três opções concretas.
- Espere a decisão do usuário.
- Não improvise.

**Se o usuário pedir algo que está fora do escopo da spec:**

- Lembre que está fora do escopo desta spec.
- Sugira anotar para a próxima spec.
- Não implemente nesta branch.

**Ao terminar o último passo:**

```
✅ Todos os passos do plano estão implementados.

Próximo passo: confirmar que cada comportamento novo tem teste e que a suíte passa por inteiro (skill `unit-testing-standards`) e, só então, verificar os critérios de aceite da spec, um por um.
Se todos passarem, atualize o estado da spec para "Implementado" (ou o
equivalente no idioma do seu repositório) e faça o commit final antes de
mergear esta branch.
```

---

## Resumo do comportamento esperado

```
/spec-impl 01-mvp-arkanoid

  Fase 1  →  Encontra specs/01-mvp-arkanoid.md
  Fase 2  →  Lê o estado → "Aprovado" (ou "Approved", etc.) → ✅ continua
  Fase 3  →  git checkout -b spec-01-mvp-arkanoid → git checkout spec-01-mvp-arkanoid
              Mostra objetivo, escopo, plano e critérios
  Fase 4  →  Implementa passo a passo com pausas
              Termina lembrando de verificar os critérios de aceite

/spec-impl 02-powerups  (estado: Rascunho / Draft)

  Fase 1  →  Encontra specs/02-powerups.md
  Fase 2  →  Lê o estado → "Rascunho" → ❌ para
              Mostra a mensagem de erro padrão
              Não cria branch, não toca no código
```

**A criação de branch é controlada pela flag `AutoCreateBranch`** em `specs/.spec-config.yml`. O padrão é `true` (cria a branch automaticamente, como mostrado acima). Defina `false` para a Fase 3 perguntar `[y/N]` antes de criar a branch.
