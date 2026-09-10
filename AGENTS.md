# AGENTS.md

Workspace para autoria de **skills de agente** — Markdown puro, sem runtime. O conteúdo principal é um fluxo de duas skills guiado por spec: `/spec` desenha uma spec, um humano aprova, `/spec-impl` implementa.

Para entender o método em si e o porquê dele, leia [README.md](./README.md). Para o índice de skills, veja [skills/engineering/README.md](./skills/engineering/README.md). Este arquivo cobre apenas o que você precisa para trabalhar _neste_ repositório.

## Estrutura

| Caminho                               | O que é                                                                                                                                                                    |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skills/<bucket>/<name>/SKILL.md`     | Uma skill. Os buckets agrupam por domínio (`engineering/`). Arquivos companheiros como `template.md` ficam ao lado do `SKILL.md` e são referenciados por caminho relativo. |
| `scripts/list-skills.sh`              | Lista o caminho de todos os `SKILL.md`.                                                                                                                                    |
| `scripts/link-skills.sh`              | Cria links simbólicos de todas as skills em `~/.claude/skills`, para desenvolvimento local.                                                                                |
| `scripts/install-to-agent.sh <agent>` | Traduz as skills para `claude`, `cursor`, `codex`, `antigravity`. **Deve ser executado a partir do repositório de destino** — ele termina com código 1 quando rodado aqui. |
| `.github/instructions/`               | Instruções de agente com escopo (carregadas ao editar arquivos que casam com o padrão).                                                                                    |
| `reference/`                          | Ignorado pelo git e ausente por padrão: uma referência de estilo vendorizada. Não crie; não edite se aparecer.                                                             |

Não existe **gerenciador de pacotes, etapa de build nem suíte de testes**. Verificar uma mudança significa reler o Markdown; para os scripts de shell, rode `bash -n` e depois exercite o script.

`specs/` deliberadamente não existe neste repositório — as skills criam essa pasta dentro dos repositórios _de destino_. Não crie uma aqui.

## Regras de autoria de skill

Detalhes e exemplos: [.github/instructions/skill-authoring.instructions.md](./.github/instructions/skill-authoring.instructions.md).

- Os corpos das skills são escritos em **português**, e toda skill deve instruir o agente a responder no idioma do prompt do usuário.
- O frontmatter deve incluir `name` (idêntico ao nome da pasta) e `description`. Skills de **fluxo** (fases e um fim determinado, como `/spec`) levam também `disable-model-invocation: true` e `argument-hint`; skills de **padrão** (conhecimento consultável, como `nextjs-feature-architecture`) não levam — o objetivo é o agente carregá-las sozinho quando o assunto aparecer.
- Como o instalador descarta o frontmatter para Cursor/Codex/Antigravity, a intenção "só roda por comando explícito" precisa estar repetida **no corpo** de cada skill de fluxo — é o bloco `> **Invocação explícita.**` no `/spec` e no `/spec-impl`.
- Nomeie por stack ou assunto, nunca por projeto: `nextjs-feature-architecture`, `nestjs-api-architecture`. O bucket `engineering/` agrupa por domínio (frontend, backend, infraestrutura convivem nele); não crie um bucket por stack.
- `allowed-tools` é uma fronteira deliberada — o `spec-impl` concede apenas comandos de git/fs somente leitura. Não amplie sem um motivo.
- O estado vivo do repositório é injetado com trechos `` !`command` `` colocados em um bloco "Contexto da sessão" no topo do corpo, antes das instruções. Datas sempre vêm de `` !`date +%F` ``, nunca do senso de "hoje" do modelo. Proteja todo trecho contra arquivos ausentes (`2>/dev/null || echo "..."`).
- O instalador remove o frontmatter YAML e reemite apenas o corpo, então **tudo que for essencial precisa estar no corpo** — comportamentos que existem só no frontmatter desaparecem no Cursor/Codex/Antigravity.
- Novas skills são descobertas automaticamente (`skills/**/SKILL.md`, tanto pelo `skills.sh` quanto pelo instalador). Adicionar uma significa criar a pasta e atualizar a tabela do `README.md` do bucket — sem registro.
- **Teste é requisito de qualquer skill que gere código**: ela aponta para a `unit-testing-standards` e inclui a exigência de teste na sua Definition of Done. O fluxo de spec também carrega isso — o plano de implementação tem o teste em cada passo e os critérios de aceite têm um item verificável de testes.

## Invariantes que sustentam o método

Quebrar isto quebra o método silenciosamente, não só o build:

- **O status é do humano.** Nunca mude `**Status:**` (nem o equivalente em qualquer idioma) por conta própria. Estados: `Rascunho` → `Em revisão` → `Aprovado` → `Implementado`, além de `Obsoleto`; todos são reconhecidos pelo significado, em qualquer idioma.
- O `/spec` **para depois de salvar o arquivo** — ele nunca oferece implementar.
- O `/spec-impl` **nunca faz commit** e se recusa a rodar a menos que o status signifique "Aprovado".
- `specs/.spec-config.yml` é semeado **apenas quando não existe**; nunca sobrescreva. `AutoCreateBranch` assume `true` quando o arquivo ou o valor estão ausentes.

## Commits e releases

As releases são automatizadas com release-please na `main`, então as mensagens de commit devem seguir o [Conventional Commits](https://www.conventionalcommits.org/): `feat:` sobe a minor, `fix:` sobe a patch, `feat!:`/`fix!:` sobe a major, e `docs:`/`chore:`/`refactor:` não geram release. Não faça commit nem push a menos que isso seja pedido.

## Arestas conhecidas

- O `install-to-agent.sh` se recusa a rodar a partir deste repositório, então teste em um diretório descartável em vez de afrouxar essa proteção.
- No ramo `cursor` do instalador, só o corpo do `SKILL.md` é copiado para `.cursor/rules/<name>.mdc` — arquivos companheiros (como um `template.md`) **não** chegam ao Cursor. Por isso o essencial precisa estar no próprio `SKILL.md`.
