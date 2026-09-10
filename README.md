<p align="center">
  <h1 align="center">Skills de Engenharia para Agentes de Código</h1>
  <p align="center">Planeje a feature. Aprove. Implemente passo a passo — e escreva no padrão.</p>
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/github/license/geraldobl58/skills">
  <img alt="Latest Release" src="https://img.shields.io/github/v/release/geraldobl58/skills">
  <img alt="GitHub Stars" src="https://img.shields.io/github/stars/geraldobl58/skills?style=social">
  <img alt="Skills" src="https://img.shields.io/badge/skills-4-blue">
</p>

## Início rápido

```bash
npx skills@latest add geraldobl58/skills
```

## Skills

**Fluxo de trabalho** — você invoca quando precisa:

| Skill        | Descrição                                                        | Argumento   |
| ------------ | ---------------------------------------------------------------- | ----------- |
| `/spec`      | Desenha o documento da feature fazendo perguntas de clarificação | —           |
| `/spec-impl` | Valida que a spec está aprovada e implementa passo a passo       | `<NN-slug>` |

**Padrões de stack** — o agente carrega sozinho quando o assunto aparece (ver [Padrões de stack](#padrões-de-stack)):

| Skill                          | Padrão                                                             |
| ------------------------------ | ------------------------------------------------------------------ |
| `/nextjs-feature-architecture` | Features Next.js em camadas, com ky, Zod, React Query e MUI.       |
| `/unit-testing-standards`      | Nenhum código com comportamento sai sem teste — em qualquer stack. |

---

## Índice

- [O que é design guiado por spec](#o-que-é-design-guiado-por-spec)
- [O problema que ele resolve](#o-problema-que-ele-resolve)
- [O procedimento de seis passos](#o-procedimento-de-seis-passos)
- [Anatomia de uma spec útil](#anatomia-de-uma-spec-útil)
- [Quando usar specs e quando não](#quando-usar-specs-e-quando-não)
- [Regras que quase ninguém segue](#regras-que-quase-ninguém-segue)
- [Instalação](#instalação)
- [Uso](#uso)
- [Padrões de stack](#padrões-de-stack)

---

## O que é design guiado por spec

Design guiado por spec é uma abordagem em que **a spec é o artefato principal do trabalho, não o código**. O código é a consequência.

Parece óbvio. A diferença em relação ao clássico "documentar antes de codar" é que aqui a spec **não é opcional nem decorativa**: ela é o contrato que guia a execução, é versionada no git e é mantida viva. Se o código diverge da spec, um dos dois está errado.

Cada spec captura as decisões de uma única feature. As specs ficam em `specs/` como arquivos `.md` numerados sequencialmente, e formam o log de decisões de design do projeto.

---

## O problema que ele resolve

Quando você trabalha com um LLM como o Claude Code, existe um fenômeno bem concreto: se você pedir _"me faça um Arkanoid com power-ups e fases"_, **ele vai improvisar**. Vai tomar 50 decisões de design implícitas (classes ou funções? estado global ou local? como as entidades são nomeadas?) sem que você veja nenhuma delas. E cada uma dessas decisões se torna um acoplamento caro de reverter depois.

O problema não é novo — humanos também improvisam — mas com um LLM ele é mais agudo:

1. **A velocidade de geração esconde o custo das decisões.** Quando um humano leva duas horas para escrever um módulo, ele tem tempo de pensar. Quando o Claude faz em 30 segundos, as decisões ficam invisíveis.
2. **Toda conversa começa do zero.** Sem uma spec, na sessão seguinte o Claude não sabe o que você decidiu antes e vai improvisar de novo, possivelmente na direção oposta.
3. **O contexto enche rápido.** Sem um documento estável para consultar, você acaba colando contexto à mão em cada prompt.

A spec resolve os três: torna as decisões explícitas, persiste entre sessões e carrega de uma vez como referência.

---

## O procedimento de seis passos

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  1. DESCREVA    │→ │  2. PLANO       │→ │   3. AJUSTE     │
│  o problema     │  │ Claude propõe   │  │ você dá         │
│  não a resposta │  │ não edita       │  │ as decisões     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
        ↑                                          │
        │                                          │
        └──────── 2-3 iterações até convergir ──────┘
                              │
                              ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    4. SALVE     │→ │   5. EXECUTE    │→ │   6. REVISE     │
│ specs/NN-       │  │ passo a passo   │  │ diff por passo  │
│ feature.md      │  │ com pausas      │  │ não no final    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### 1. Descreva

Você descreve a feature ao Claude em termos **do problema**, não da solução. Se você dita a solução, o Claude só formata — você perde a capacidade dele de propor estrutura.

### 2. Modo plano

Você ativa o modo plano (no modo plano o Claude não pode escrever arquivos, só ler e propor). O Claude responde com um documento estruturado: escopo, modelo de dados, plano de implementação e critérios de aceite.

### 3. Ajuste

Você lê o plano com resistência e dá **decisões concretas**. "Tira X do escopo", "os dados vivem em JSON, não em módulos JS", "adiciona uma seção de riscos". Você itera 2-3 vezes.

### 4. Salve

Quando a spec está afiada, você a salva em `specs/NN-slug.md` com status `Rascunho`. Você sai do chat, **relê fora do editor** e só quando está satisfeito muda o status para `Aprovado` na mão. Essa mudança é feita pelo humano, não pelo Claude.

### 5. Execute

Você sai do modo plano e pede ao Claude para implementar a spec **passo a passo**, parando depois de cada passo do plano de implementação. A pausa entre os passos é o que faz o método funcionar.

### 6. Revise

Depois de cada passo, você revisa o diff. Se estiver bom, você continua. Se não, você corrige na hora — não no final com 600 linhas misturadas.

---

## Anatomia de uma spec útil

Nem todo documento dá conta do recado. Uma spec útil tem seis partes — se faltar alguma, provavelmente não é o suficiente para guiar a execução.

### 1. Objetivo em uma frase

Se não cabe em uma frase, a feature é grande demais. Divida antes de escrever qualquer outra coisa.

### 2. Escopo explícito + o que NÃO está no escopo

O "fora do escopo" é tão importante quanto o "dentro do escopo". Sem ele, as fronteiras ficam borradas e o scope creep aparece durante a implementação. Registre as coisas que foram mencionadas mas decididas adiar.

### 3. Modelo de dados

Estruturas e nomes concretos. Se você diz "o módulo de fases", diga `src/levels.js`. Se você diz "uma chave", dê a string exata. Esta seção é a mais citada depois em outras specs e skills.

### 4. Plano de implementação ordenado

Passos numerados e sequenciais. **Cada passo deve deixar o sistema em estado funcional.** Se um passo exige mais de 30-50 linhas de código, divida. O último passo não é "testar tudo" — isso são os critérios de aceite.

### 5. Critérios de aceite

Um checklist booleano verificável. Cada item pode ser respondido com sim ou não.

- ❌ "Funciona bem" — não é verificável
- ❌ "Boa UX" — subjetivo
- ❌ "Sem bugs" — não é operacional
- ✅ "Apertar Esc pausa o jogo e mostra o menu" — verificável

### 6. Decisões tomadas e descartadas

O que você considerou e por que escolheu o que escolheu. **Isso é ouro daqui a três meses**, quando alguém perguntar _"por que a persistência usa uma chave versionada?"_. A resposta mora ali.

Idealmente cada decisão tem uma razão curta. Decisões sem razão são as primeiras a serem questionadas depois.

---

## Quando usar specs e quando não

Essa arquitetura tem um custo. Não aplique a tudo.

### SIM — escreva uma spec quando:

- A tarefa tocar **mais de dois arquivos**.
- Existirem **decisões caras de reverter** (schemas de dados, formatos, APIs).
- A feature levar **mais de uma sessão** de Claude Code.
- Existir um **contrato que outros artefatos vão reutilizar** (outra spec, uma skill, um hook).
- For algo que você vai **esquecer em uma semana**.

### NÃO — use um prompt direto quando:

- For uma **correção pontual de bug**.
- For um **refactor mecânico** (renames, movimentação de arquivos).
- For um **experimento exploratório** em que o objetivo é descobrir a decisão, não executá-la.
- A tarefa **caber em um prompt** e for entendida na primeira leitura.
- For uma **tarefa pontual** que não vai se repetir.

### Regra mental

> **Se você está com vontade de abrir o modo plano, provavelmente você precisa dele.**
> **Se planejar a feature te dá tédio, provavelmente você não precisa.**

Bom senso vence a regra — mas o bom senso é treinado pelas duas colunas acima.

---

## Regras que quase ninguém segue

Quatro padrões de uso que distinguem o método funcionando do método como burocracia decorativa:

### 1. Na fase de descrição, descreva o problema, não a solução

❌ _"Adicione um array de fases carregado de JSON, uma função `loadLevel()` e persistência com localStorage versionado."_

Isso já é uma spec mal escrita por você. O Claude só vai formatar.

✅ _"Quero que o jogo deixe de ser de tela única. A próxima feature é: progressão por fases com dificuldade crescente, e persistência de recordes entre sessões."_

Essa segunda versão deixa espaço para o Claude **decidir** e para você **revisar**. É a natureza do fluxo.

### 2. Na fase de ajuste, dê decisões concretas, não sugestões

O modo plano é onde **você dirige**. "Tira X", "o formato é JSON", "adiciona riscos". Se você disser "acho que talvez seria bom se...", o Claude vai deixar como está.

### 3. Durante a execução, peça pausas entre os passos

A diferença é:

- **Sem pausas:** o Claude despeja 400 linhas. Você revisa um commit gigante. Se algo está errado no passo 2, está misturado com mudanças dos passos 5 e 6. Doloroso.
- **Com pausas:** o Claude despeja 50-80 linhas (passo 1). Você lê o diff. Você aprova ou ajusta. Ele vai para o passo 2. Cada passo é um commit limpo. Reverter é trivial.

### 4. Se no meio da execução você quiser mudar algo, volte ao passo 2 — nunca improvise

No meio da implementação surge uma ideia. O movimento certo é: pare, volte ao modo plano, atualize a spec, saia, continue. **Não improvise no código.**

Essa separação é o que evita scope creep silencioso.

---

## Instalação

### Opção 1 — skills.sh (recomendada, Claude Code)

```bash
npx skills@latest add geraldobl58/skills
```

Para desinstalar:

```bash
npx skills@latest remove geraldobl58/skills
```

### Opção 2 — Outros agentes (Cursor, Codex, Antigravity)

```bash
git clone https://github.com/geraldobl58/skills ~/.skills
cd ~/seu-projeto
~/.skills/scripts/install-to-agent.sh <agent>
```

`<agent>` pode ser `claude`, `cursor`, `codex` ou `antigravity`.

| Agente        | O que é escrito                                                                                 |
| ------------- | ----------------------------------------------------------------------------------------------- |
| `claude`      | Cria links simbólicos de cada skill em `.claude/skills/` (escopo do projeto)                    |
| `cursor`      | Gera arquivos `.cursor/rules/<name>.mdc`. Invoque com `@spec`, `@spec-impl`, etc.               |
| `codex`       | Adiciona um bloco `## Skills` ao `AGENTS.md` e copia os corpos das skills para `.codex/skills/` |
| `antigravity` | Copia os corpos das skills para `.antigravity/skills/`                                          |

> Cursor e Codex não suportam nativamente o `argument-hint` nem o `disable-model-invocation` do frontmatter do Claude Code. O instalador descarta esses campos e mantém o corpo — o fluxo é o mesmo, só o gatilho muda.

### Opção 3 — Manual

```bash
# Pessoal (todos os seus projetos)
mkdir -p ~/.claude/skills
cp -r skills/engineering/spec ~/.claude/skills/
cp -r skills/engineering/spec-impl ~/.claude/skills/

# Ou por projeto (versionado no git)
mkdir -p .claude/skills
cp -r skills/engineering/spec .claude/skills/
cp -r skills/engineering/spec-impl .claude/skills/
```

Para o método funcionar, você também precisa criar a pasta `specs/` na raiz do projeto:

```bash
mkdir specs
```

Opcionalmente, adicione um `specs/README.md` documentando a convenção (veja o exemplo neste repositório).

---

## Uso

### Ciclo completo de uma feature

```bash
# 1. Desenhe a spec com perguntas de clarificação
/spec levels-and-highscores

# O Claude lê o arquivo de memória do projeto (CLAUDE.md, AGENTS.md, GEMINI.md ou README.md) e as specs existentes em specs/, faz perguntas
# em blocos, desenvolve a spec seção por seção,
# e no final salva como specs/03-levels-and-highscores.md
# com status: Rascunho.

# 2. Releia a spec fora do chat e aprove na mão
# (abra o arquivo no editor, mude Status: Rascunho → Aprovado)

# 3. Implemente a spec aprovada
/spec-impl 03-levels-and-highscores

# O Claude valida que o status é Aprovado, cria a branch
# spec-03-levels-and-highscores, muda para ela, mostra
# o resumo da spec, e começa a implementação passo a passo
# com pausas para revisar os diffs.
```

### O que cada skill faz

#### `/spec [tópico-curto]`

Desenha o documento da feature. Passa por quatro fases:

1. **Contexto** — lê o arquivo de memória do projeto (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` ou `README.md`, o primeiro que existir) e as specs anteriores.
2. **Clarificação** — faz perguntas em blocos de 3-5 até a feature estar claramente definida.
3. **Desenvolvimento seção por seção** — gera e confirma cada seção da spec antes de seguir.
4. **Salvar** — escreve o arquivo em `specs/NN-slug.md` com status `Rascunho`.

#### `/spec-impl <NN-nome>`

Implementa uma spec aprovada. Passa por quatro fases:

1. **Identificar** — localiza o arquivo da spec.
2. **Validar** — verifica se o status é `Aprovado`. Se não for, para.
3. **Criar branch** — `git checkout -b spec-NN-slug` e muda para ela.
4. **Implementar** — passo a passo com pausas, mostrando o resumo da spec primeiro.

> **Controle de branch:** a Fase 3 lê a flag `AutoCreateBranch` de `specs/.spec-config.yml`. O padrão é `true` (cria a branch automaticamente). Defina `false` para o `/spec-impl` perguntar `[y/N]` antes de criar qualquer branch — útil se a nomenclatura de branches faz parte do seu próprio fluxo de Git.
>
> ```yaml
> # specs/.spec-config.yml
> AutoCreateBranch: false
> ```

### Estados da spec

| Estado         | Significado                                                           |
| -------------- | --------------------------------------------------------------------- |
| `Rascunho`     | A skill `/spec` gerou a spec, mas o humano ainda não releu.           |
| `Em revisão`   | O humano está revisando ou iterando com o Claude.                     |
| `Aprovado`     | O humano leu e autorizou. O `/spec-impl` só funciona com este estado. |
| `Implementado` | O código existe e passa nos critérios de aceite.                      |
| `Obsoleto`     | Substituída por outra spec. Não é apagada — é referenciada.           |

**Mudar o status para `Aprovado` é um ato humano deliberado.** É a única assinatura no contrato — o Claude não pode aprovar o próprio trabalho.

> Os rótulos de status são agnósticos de idioma. O `/spec-impl` só exige que o status signifique **Aprovado** — `Aprovado`, `Approved` ou o equivalente em qualquer idioma funcionam. O mesmo vale para os outros estados. Escolha os rótulos que seu time preferir e mantenha a consistência.

---

## Padrões de stack

Skills de fluxo (`/spec`, `/spec-impl`) servem para **conduzir um trabalho**. Skills de padrão servem para **definir como o código deve ser escrito** — não têm fases nem fim, são conhecimento que o agente carrega quando o assunto aparece.

| Skill                                                                                      | Padrão                                                                                                                                                                                           |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`nextjs-feature-architecture`](./skills/engineering/nextjs-feature-architecture/SKILL.md) | Features Next.js em camadas: estrutura de pastas, `http/` → `actions/` → `hooks/` → `components/`, Server Actions, React Query, MUI e uma Definition of Done com 6 critérios.                    |
| [`unit-testing-standards`](./skills/engineering/unit-testing-standards/SKILL.md)           | Teste obrigatório para todo código com comportamento, em qualquer stack (front, back, worker, CLI). É a única skill que traz **código executável**: o script da trava e o hook de fim de sessão. |

### Como usar

Não há comando a decorar:

- **Automático** — peça _"crie a feature de faturamento em `src/features`"_ e o agente carrega a skill sozinho, porque a `description` dela casa com a tarefa.
- **Explícito** — digite `/nextjs-feature-architecture` para trazer as regras para a conversa e trabalhar a partir delas.
- **Como checklist de review** — peça _"revise essa feature contra a nextjs-feature-architecture"_. A seção 6 dela é uma Definition of Done com critérios verificáveis (zero lógica nos componentes, tipagem centralizada, um arquivo por operação, erros tratados, testes, sem proxy de API).
- **Como trava de verdade** — a `unit-testing-standards` passa do texto: ela traz o script `check-test-pairs.sh` e um hook de fim de sessão que **bloqueiam** a entrega enquanto houver arquivo de código sem teste irmão. Regra em Markdown orienta; script e hook garantem. A instalação está logo abaixo.

É esse terceiro uso que faz a skill valer a pena no dia a dia: ela vira um critério objetivo de revisão, em vez de "achei que ficou bom".

### Como ativar a trava de testes (uma vez por projeto)

A `unit-testing-standards` só bloqueia alguma coisa depois que o script e o hook estão **no projeto de destino** — a skill sozinha apenas orienta. São três passos, uma vez por projeto.

**1. Copiar a trava**

```bash
mkdir -p .github/hooks
cp <pasta-da-skill>/scripts/check-test-pairs.sh .github/hooks/
cp <pasta-da-skill>/hooks/verify-tests.json .github/hooks/
chmod +x .github/hooks/check-test-pairs.sh
```

`<pasta-da-skill>` é onde a skill ficou instalada: `~/.claude/skills/unit-testing-standards`, `.claude/skills/unit-testing-standards` ou o repositório clonado em `~/.skills/skills/engineering/unit-testing-standards`.

> **No Cursor** o instalador copia apenas o corpo da skill para `.cursor/rules/`. Os dois arquivos acima vêm do repositório clonado.

**2. Conferir que está funcionando**

```bash
bash .github/hooks/check-test-pairs.sh   # 0 = tudo coberto, 2 = falta teste
```

O script roda dentro de um repositório git e olha o que está modificado ou novo. Se ele acusar um arquivo que é isento por natureza, marque nas primeiras linhas dele:

```ts
// test-ignore: DTO sem comportamento
```

A exceção fica visível no diff, para alguém revisar — em vez de escondida na configuração do script.

**3. Fechar no CI (a autoridade final)**

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0 # a trava precisa do histórico para achar o merge-base

- name: Testes obrigatórios
  run: |
    bash .github/hooks/check-test-pairs.sh --base origin/${{ github.base_ref }}
    npm test        # troque pelo comando do projeto: go test ./..., pytest, ./gradlew test
```

O hook local impede o agente de encerrar sem teste; o CI é o que vale para um commit feito à mão, fora do editor. Sem esse passo, a garantia existe só na sua máquina.

Com clone raso (`fetch-depth: 1`, o padrão do checkout) o script sai com `1` em vez de passar em silêncio — de propósito: uma trava mal configurada que passa dá falsa sensação de cobertura.

### Como encaixar a próxima (backend, mobile, …)

Não existe registro nem configuração: **criar a pasta é o suficiente**. O `skills.sh` e o `scripts/install-to-agent.sh` descobrem qualquer `skills/**/SKILL.md` automaticamente.

```text
skills/engineering/
├── nextjs-feature-architecture/   # padrão do frontend
├── unit-testing-standards/        # regra transversal (serve front e back)
├── nestjs-api-architecture/       # <- o padrão do backend entraria aqui
├── spec/
└── spec-impl/
```

O bucket `engineering/` agrupa por **domínio**, não por stack — frontend, backend e infraestrutura convivem nele. Um padrão novo entra como pasta irmã, com `name` igual ao nome da pasta, `description` em português dizendo quando usar, e o corpo com as regras. Depois é só adicionar a linha na tabela do [`skills/engineering/README.md`](./skills/engineering/README.md).

Duas convenções que valem para qualquer skill nova:

- **Skill de fluxo** (fases, um fim determinado) leva `disable-model-invocation: true` — só roda quando você chama. Repita essa intenção no corpo (`> **Invocação explícita.**`), porque o frontmatter não sobrevive ao instalador no Cursor/Codex/Antigravity.
- **Skill de padrão** **não** leva esse campo: o objetivo é o agente carregá-la sozinho quando o assunto aparecer.

E uma que vale para qualquer skill que **gere código** (padrão de stack ou fluxo): ela aponta para a `unit-testing-standards` e exige o teste na sua Definition of Done. Nada é entregue sem teste — é regra do repositório, não preferência de stack.

---

## Por que as duas skills funcionam como um par

```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│   /spec     Claude pergunta e desenha                     │
│             ↓                                             │
│             specs/NN-slug.md  (Status: Rascunho)          │
│                                                           │
│   ──────── o humano relê e aprova ────────                │
│             ↓                                             │
│             specs/NN-slug.md  (Status: Aprovado)          │
│                                                           │
│   /spec-impl  Claude valida e implementa                  │
│             ↓                                             │
│             branch spec-NN-slug + código                  │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

O intervalo entre as duas skills — reler e mudar o status na mão — é deliberado. É o único momento em que **só você pode fazer algo**. Sem esse intervalo, o método degrada para "o Claude escreve documentação bonita e depois escreve o código que der na telha".

---

## Releases

Este projeto usa [release-please](https://github.com/googleapis/release-please) para releases automatizadas. As mensagens de commit devem seguir o [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo                        | Efeito                |
| ------------------------------ | --------------------- |
| `feat:`                        | Sobe a versão minor   |
| `fix:`                         | Sobe a versão patch   |
| `feat!:` / `fix!:`             | Sobe a versão major   |
| `docs:`, `chore:`, `refactor:` | Nenhum bump de versão |

---

## Licença

MIT

---

_Se você encontrar uma forma de melhorar o método ou as skills, abra uma issue ou um PR. A parte mais valiosa de uma skill pessoal é que ela evolui com o uso._
