---
name: "Autoria de Skills"
description: "Use ao criar, editar ou revisar um SKILL.md, ao adicionar uma skill em skills/ ou ao alterar scripts/install-to-agent.sh. Cobre requisitos de frontmatter, injeção de contexto com bang-command, fronteiras de allowed-tools e os invariantes de status que são exclusivos do humano."
applyTo: "skills/**,scripts/install-to-agent.sh"
---

# Autoria de Skills neste Repositório

As skills daqui são distribuídas para o repositório de outras pessoas, então são tratadas como API pública: o frontmatter é lido por ferramentas de terceiros, os corpos são copiados literalmente para o formato de outros agentes, e o texto é o produto.

## Formato da pasta

```
skills/<bucket>/<name>/
├── SKILL.md        # obrigatório; frontmatter + corpo
└── template.md     # companheiro opcional, referenciado por caminho relativo
```

- `<bucket>` agrupa por domínio (`engineering/` hoje). Crie um novo bucket apenas quando a skill realmente não pertencer a nenhum existente.
- `<name>` deve ser igual ao campo `name` do frontmatter.
- A descoberta é por convenção: `skills/**/SKILL.md` é encontrado automaticamente tanto pelo `skills.sh` quanto pelo `scripts/install-to-agent.sh`. Não adicione arquivos de registro.
- Nomeie por stack ou assunto, nunca por projeto: `nextjs-feature-architecture`, `nestjs-api-architecture`. O bucket `engineering/` agrupa por domínio — frontend, backend e infraestrutura convivem nele; não crie um bucket por stack.
- Mantenha o `SKILL.md` **autossuficiente**: o ramo `cursor` do instalador copia apenas o corpo do `SKILL.md` e descarta arquivos companheiros, então tudo que for essencial precisa estar nele.
- Adicione a nova skill à tabela do `README.md` do bucket (`skills/engineering/README.md`) e, se ela for de um tipo novo, à tabela do `README.md` da raiz.
- Adicione a nova skill à tabela do `README.md` do bucket (`skills/engineering/README.md`).

## Frontmatter

```yaml
---
name: spec-impl
description: Implementa uma spec aprovada. Valida que o estado significa "Aprovado" (em qualquer idioma), cria uma branch git com o nome da spec, muda para ela e começa a implementação passo a passo com pausas para revisar os diffs.
disable-model-invocation: true
argument-hint: <NN-spec-name>
allowed-tools: Read, Glob, Grep, Edit, Write, AskUserQuestion, Bash(git status:*), Bash(git log:*)
---
```

- `name` — deve ser igual ao nome da pasta. Uma divergência falha silenciosamente na maioria das ferramentas.
- `description` — em **português**, como todas as skills deste repositório; rica em palavras-chave, e diga _quando_ usar a skill ("Use quando…"), porque este é o único texto que o agente vê antes de decidir carregar a skill.
- `disable-model-invocation: true` — para **skills de fluxo**, que têm fases e um fim determinado (como o `/spec`). **Não** use em **skills de padrão/conhecimento** (como a `nextjs-feature-architecture`): sem esse campo o agente carrega a skill sozinho quando o assunto aparece, que é exatamente o objetivo. A invocação por `/` funciona nos dois casos.
- A intenção "só roda quando o usuário chama" precisa estar **repetida no corpo** (ex.: `> **Invocação explícita.**`), porque o instalador descarta o frontmatter em Cursor/Codex/Antigravity.
- `argument-hint` — curto, descreve o argumento, não a skill. Só faz sentido em skill de fluxo que aceita argumento; um padrão de arquitetura não tem argumento — omita.
- `allowed-tools` — uma fronteira real, não documentação. Restrinja o Bash comando a comando (`Bash(git status:*)`), nunca conceda um `Bash` solto. Se a skill não pode alterar nada, conceda apenas ferramentas de leitura.
- Coloque qualquer valor com dois-pontos entre aspas; use espaços, nunca tabs.

Atenção: Cursor e Codex recebem apenas o corpo sem frontmatter, então `allowed-tools`, `argument-hint` e `disable-model-invocation` se perdem para eles. A segurança precisa ser reafirmada no corpo como regra absoluta (ex.: "nunca faça commit", "pare e aguarde confirmação").

## Injeção de contexto

O estado vivo é injetado no momento de carregar a skill com um trecho bang-command, em um bloco `## Contexto da sessão` colocado logo depois do título `# /nome — título` e antes das instruções:

```markdown
## Contexto da sessão

Branch atual:
!`git branch --show-current`

Specs disponíveis:
!`ls specs/ 2>/dev/null || echo "A pasta specs/ não existe"`
```

Regras:

- Sempre proteja com `2>/dev/null || echo "…"` — as skills rodam em repositórios onde esses caminhos podem não existir.
- Quando um valor tem padrão, imprima o padrão junto com a mensagem de "arquivo ausente", para o modelo ler um valor utilizável de qualquer forma (veja o trecho de `AutoCreateBranch` no `spec-impl`).
- Nunca deixe o modelo inferir datas, branches ou listas de arquivos a partir das próprias suposições; injete-os.
- Mantenha os trechos baratos: `ls`, `cat`, `git status`, `git log`.
- O modelo só pode rodar o que o `allowed-tools` permite — um trecho cujo comando não está na lista não poderá ser reexecutado interativamente.

## Convenções de corpo

Siga as skills existentes como referência (`skills/engineering/spec/SKILL.md` e `skills/engineering/spec-impl/SKILL.md` para fluxo; `skills/engineering/nextjs-feature-architecture/SKILL.md` e `skills/engineering/unit-testing-standards/SKILL.md` para padrão):

- Imperativo, segunda pessoa, direto. Sem hesitação ("se você não se importar", "talvez você pudesse").
- Numere fases nomeadas para fluxos de vários passos, e diga que elas rodam **em ordem** e que uma fase que falha impede a seguinte.
- Inclua uma frase exigindo respostas no idioma do usuário: _"Suas respostas devem estar no mesmo idioma do prompt inicial."_
- Termine com uma lista `## Regras absolutas` com o que a skill nunca deve fazer. É a única imposição que sobrevive à remoção do frontmatter.
- Dê um exemplo curto do comportamento esperado quando o fluxo não é óbvio (o arquivo do `/spec-impl` termina com um traço compacto de duas invocações).
- **Skills que geram código exigem teste.** Toda skill de padrão de stack (ou de fluxo que escreve código) aponta para a `unit-testing-standards` e traz a exigência de teste na sua Definition of Done. O fluxo de spec segue a mesma regra: cada passo do plano de implementação carrega o teste e os critérios de aceite têm um item verificável (`a suíte passa por inteiro`, não `tem testes`). Não crie uma segunda versão da regra de testes — referencie a existente.

## Invariantes fáceis de quebrar

- Não adicione nada que mude `**Status:**` automaticamente. Só a Fase 4 do `/spec` escreve o arquivo, sempre como `Rascunho`.
- O `/spec` não deve propor implementação depois de salvar; o `/spec-impl` não deve fazer commit e deve abortar em qualquer status que não signifique "Aprovado".
- Nunca sobrescreva um `specs/.spec-config.yml` existente; semeie apenas quando estiver ausente.
- Reconheça estados e títulos de seção **pelo significado**, nunca por uma string fixa em inglês — estas skills são usadas em repositórios escritos em qualquer idioma.

## Acoplamento com o instalador

O `scripts/install-to-agent.sh` descobre as skills com `find`, remove o frontmatter com `awk` (`skill_body`) e lê a `description` com `fm`. Quando mexer nele:

- Mantenha `set -euo pipefail`; coloque todo caminho entre aspas (caminhos de destino podem conter espaços).
- Adicionar um agente significa um novo ramo no `case`, além do texto de uso no topo e da tabela no `README.md`.
- Mantenha a proteção `TARGET = SKILLS_REPO` que se recusa a rodar dentro deste repositório; teste em um diretório descartável em vez disso.
- Mudanças no shell são verificadas com `bash -n scripts/install-to-agent.sh` e uma execução real a partir de um repositório descartável.
