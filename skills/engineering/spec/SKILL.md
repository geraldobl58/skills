---
name: spec
description: Desenha e desenvolve specs seguindo o método guiado por spec. Faz perguntas de clarificação antes de propor estrutura, e constrói a spec seção por seção. Use ao iniciar uma feature grande, antes de escrever código.
disable-model-invocation: true
argument-hint: "descrição curta da feature ou requisito"
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(ls:*), Bash(cat:*), Bash(date:*)
---

# /spec — Desenhista de spec guiado

## Contexto da sessão

Data de hoje (use no cabeçalho da spec, nunca adivinhe):
!`date +%F`

Specs que já existem:
!`ls specs/ 2>/dev/null || echo "A pasta specs/ ainda não existe"`

---

Esta skill ajuda você a produzir uma spec útil seguindo o método guiado por spec. **Você não escreve código aqui.** Seu trabalho é ajudar o usuário a clarificar o que ele quer construir, fazer perguntas quando algo não estiver definido o suficiente, e desenvolver a spec seção por seção até ela estar pronta para ser salva em `specs/`.

> **Invocação explícita.** Esta skill só roda quando o usuário a chama (`/spec`). Ela conduz uma sessão de perguntas e escreve um arquivo — não a inicie por conta própria só porque a conversa mencionou uma feature nova. Se parecer o caso, sugira `/spec` e espere a decisão dele.

## Filosofia

Uma spec não é documentação decorativa. É o contrato que guia a execução posterior. Se a spec é vaga, o código improvisa. É por isso que este fluxo é **deliberadamente lento na fase de definição** e **rápido na fase de escrita**.

Leia `template.md` (no mesmo diretório desta skill) para ver a estrutura completa que a spec vai seguir. Apoie-se nele em cada passo.

## Fluxo do comando

- Siga as quatro fases em ordem. **Nunca pule a Fase 2** — as perguntas são o ponto inteiro. Se o usuário quiser ir mais rápido, lembre que o custo de uma spec ruim é pago depois, no código. (A Fase 3 tem um caminho rápido quando a Fase 2 está genuinamente completa; veja abaixo.)
- Suas respostas devem estar no mesmo idioma do prompt inicial. Ex.: se o prompt inicial está em espanhol, suas respostas devem estar em espanhol; se está em inglês, em inglês.

### Fase 1 — Entenda o contexto

Antes de fazer perguntas sobre a feature, garanta que você tem contexto do projeto:

1. Leia o arquivo de memória do projeto, se existir. Tente na ordem e pare no primeiro que encontrar: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`. Isso adapta a skill a qualquer agente que a esteja executando (Claude Code, Codex, Gemini CLI, etc.).
2. Olhe a listagem de `specs/` no contexto da sessão acima para ver quais specs já existem e como estão numeradas.
3. Se existirem specs anteriores, leia pelo menos as duas mais recentes para captar as convenções do projeto — incluindo o **idioma** em que estão escritas e a redação exata que usam para estados e títulos de seção. Uma spec nova precisa combinar com as existentes.

Se o argumento `$ARGUMENTS` vier vazio, peça ao usuário uma descrição inicial **de uma única frase** sobre o que ele quer construir. Se a descrição não couber em uma frase, esse é o primeiro sinal de que a feature é grande demais — sugira dividi-la antes de continuar.

### Fase 2 — Clarifique com perguntas

Esta é a fase mais importante do comando. Seu trabalho aqui é **detectar ambiguidades e perguntar**, não supor.

Faça perguntas em blocos de 3 a 5 por vez (não uma pergunta isolada seguida de outra pergunta isolada — isso é exaustivo). Depois de cada bloco, espere a resposta antes de continuar.

**Categorias de pergunta que você deve sempre considerar:**

- **Escopo:** o que está dentro e o que NÃO está? Que partes da feature ficam adiadas para outra spec?
- **Dados:** que estruturas novas são introduzidas? Como são nomeadas? Onde vivem?
- **Integração:** esta feature depende de specs anteriores? Ela modifica algo existente ou apenas adiciona?
- **Persistência:** algo é salvo entre sessões? Onde? Com qual versionamento?
- **UX e estados:** como fica quando funciona? Como fica quando falha? Existem estados intermediários?
- **Riscos:** o que pode quebrar isto? O que acontece no caso degradado?
- **Decisões fechadas:** existe alguma decisão que o usuário já tomou e não quer reabrir?

**Como formular as perguntas:**

- Use perguntas concretas, não abertas. ❌ "Como você imagina a persistência?" → ✅ "A persistência é localStorage, IndexedDB ou um arquivo JSON em disco?"
- Quando oferecer opções, dê 2–4, marque qual é a sua recomendação e por quê.
- Se o seu agente expõe uma ferramenta nativa de pergunta de múltipla escolha (no Claude Code: `AskUserQuestion`), use-a nesses blocos em vez de escrever as opções como texto — o usuário escolhe em vez de digitar. Coloque a sua recomendação primeiro e rotule-a. Recorra a uma lista numerada em markdown quando essa ferramenta não existir.
- Se você identificar uma resposta que abriria a caixa de Pandora (ex.: "e também queremos multiplayer"), aponte que ela merece uma spec própria e pergunte se deixamos isso fora do escopo desta.

**Quando parar de perguntar:**

Pare quando você conseguir responder estas três perguntas sem supor nada:

1. Quais arquivos vão aparecer ou mudar?
2. Qual é o primeiro passo executável e qual é o último?
3. Como eu verifico que a feature está pronta?

Se você ainda não consegue responder alguma delas, continue perguntando.

### Fase 3 — Escreva a spec

Com a Fase 2 encerrada, decida como escrever:

**Se você já tem toda a informação de que precisa** — ou seja, consegue responder às três perguntas da Fase 2 (quais arquivos mudam, quais são o primeiro e o último passos executáveis, como verificar que está pronta) **sem supor nada** — então **não vá seção por seção**. Escreva a spec completa e vá direto para a Fase 4 para salvar o arquivo. Não peça confirmação seção a seção, e não mostre um rascunho para aprovação antes: o usuário já respondeu tudo na Fase 2, e perguntar de novo é atrito. O usuário revisa o arquivo salvo e pede mudanças se precisar.

**Só se ainda faltar informação** (o usuário cortou a Fase 2, uma resposta foi vaga, ou alguma seção não pode ser escrita sem inventar algo), desenvolva as seções **uma a uma**, mostrando cada uma e esperando confirmação antes de passar para a próxima.

Nos dois casos o conteúdo segue a mesma ordem:

1. **Cabeçalho** (estado, dependências, data, objetivo em uma frase). O objetivo em uma frase é crítico — se não couber em uma frase, volte para a Fase 2.
2. **Escopo** (o que está dentro e o que NÃO está). O "não está" precisa ser explícito.
3. **Modelo de dados** (estruturas concretas com nomes reais). Se a feature não introduz dados novos, pule esta seção e diga isso explicitamente.
4. **Plano de implementação** (passos numerados, cada um deixando o sistema funcional).
5. **Critérios de aceite** (checklist booleano, não aspiracional).
6. **Decisões tomadas e descartadas** (com justificativa breve).
7. **Riscos identificados** (apenas se aplicável — se não houver riscos relevantes, pule).

**Depois de cada seção (apenas no modo seção por seção):**

- Mostre a seção formatada em markdown.
- Pergunte: "Esta seção fica assim ou você quer ajustar algo?"
- Se o usuário pedir mudanças, aplique e mostre de novo.
- Só passe para a próxima seção quando o usuário confirmar.

**Erros comuns a evitar:**

- Gerar critérios de aceite que não são verificáveis ("que funcione bem").
- Colocar no plano de implementação coisas que não estão no escopo.
- Supor nomes de arquivos ou estruturas que o usuário não confirmou.
- Pular a seção de decisões — é a seção com mais valor no longo prazo.
- Escrever critérios de aceite sem um item verificável de testes (`a suíte passa por inteiro`, não `tem testes`) e um plano cujos passos não carregam o teste junto — ver a skill `unit-testing-standards`.

### Fase 4 — Salve a spec

Quando o conteúdo estiver pronto (ou porque você já tinha tudo, ou porque todas as seções foram confirmadas):

1. Determine o próximo número sequencial a partir da listagem de `specs/` no contexto da sessão. Pegue o maior número existente e some um, com dois dígitos. Se a última é `02-powerups.md`, esta será `03-`. Se `specs/` está vazia ou não existe, comece em `01-`.
2. Gere um slug curto em kebab-case a partir do objetivo (ex.: `levels-and-highscores`). Veja **Argumentos** abaixo para o caso em que `$ARGUMENTS` é o slug.
3. Use a data do contexto da sessão acima no campo `**Data:**`. **Nunca escreva uma data que você não leu de lá.**
4. Escreva o arquivo direto em `specs/NN-slug.md` com todas as seções. **Não peça permissão para escrever e não pergunte se o nome do arquivo serve** — anuncie o caminho na confirmação final. Só pergunte se o arquivo de destino já existir.
5. Marque o estado como `Rascunho` por padrão (ou a palavra equivalente usada pelas specs existentes neste repositório). **Não marque como `Aprovado` automaticamente** — o usuário faz isso depois de reler.
6. Se o cabeçalho listar dependências (`**Depende de:** SPEC 01`), verifique se cada spec referenciada realmente existe em `specs/`. Se alguma não existir, diga isso em vez de escrever uma referência quebrada.
7. **Semeie o arquivo de configuração se ele não existir.** Verifique `specs/.spec-config.yml`. Se estiver **ausente**, crie com o conteúdo padrão abaixo. Se **já existir, deixe intocado** — nunca sobrescreva as configurações do usuário.

   ```yaml
   # configuração do fluxo de spec
   #
   # AutoCreateBranch — controla se o /spec-impl cria a branch git automaticamente.
   #   true  (padrão) → o /spec-impl cria e muda para spec-NN-slug sem perguntar
   #   false          → o /spec-impl pede confirmação [y/N] antes de criar a branch
   AutoCreateBranch: true
   ```

8. Confirme ao usuário:
   - Caminho do arquivo criado.
   - Lembrete: a spec está em estado `Rascunho`. Mude para `Aprovado` depois de reler.
   - Se você acabou de criar `specs/.spec-config.yml`, mencione que ele existe e que `AutoCreateBranch` é `true` por padrão (defina `false` para controlar a criação de branch você mesmo).
   - Próximo passo: depois de revisada e aprovada, rode `/spec-impl NN-slug` para implementá-la.
   - **Pare aqui.** Não proponha implementar a spec, escrever código nem qualquer outra ação além desta confirmação.

## Regras absolutas

- **Nunca escreva código durante este comando.** Apenas o arquivo `.md` da spec no final.
- **Nunca proponha implementar a spec depois de salvá-la.** Seu trabalho termina quando o arquivo é escrito. O usuário roda `/spec-impl` quando estiver pronto.
- **Nunca assuma decisões que o usuário não confirmou.** Se faltar informação, pergunte — na Fase 2, que é onde as perguntas pertencem.
- **Não pergunte de novo na Fase 3 o que já foi respondido na Fase 2.** Se a informação está completa, escreva a spec inteira e salve. A confirmação seção por seção é o recurso para informação incompleta, não o padrão.
- **Se o usuário quiser acelerar e pular a Fase 2**, lembre: "Perguntas agora economizam horas depois. Tem certeza de que quer pular?". Se ele insistir, respeite a decisão dele mas registre na seção de decisões da spec ("Definição rápida, sem clarificação detalhada").
- **Se a feature for grande demais** (não cabe em uma frase, toca mais de três áreas do sistema, exige decisões em quatro ou mais domínios), proponha dividi-la em duas ou mais specs antes de continuar.

## Tom ao fazer perguntas

Seja direto e específico. Não peça desculpas por perguntar. Não use frases como "se você não se importar..." ou "será que você poderia...". O usuário invocou esta skill exatamente porque quer que você faça perguntas. Use perguntas concretas, uma por linha quando houver várias, e numere-as para ficarem fáceis de responder.

Exemplo de um bloco bem formado:

> Antes de escrever o modelo de dados preciso clarificar três coisas:
>
> 1. **Persistência.** localStorage, IndexedDB ou um arquivo JSON em disco? Recomendação: localStorage se os dados couberem em <5MB e não precisarem de consultas.
> 2. **Versionamento de schema.** O que acontece quando o formato muda? Opções: (a) prefixo de versão na chave, (b) ignorar e reconstruir, (c) migrar no carregamento.
> 3. **Privacidade.** Os dados são sensíveis? Se sim, estão cifrados? São apagados no logout?

## Argumentos

`$ARGUMENTS` é **a descrição da feature**, não o nome do arquivo. Trate-o como ponto de partida da Fase 1 e derive o slug do objetivo na Fase 4.

A única exceção: se `$ARGUMENTS` já for um único token em kebab-case sem espaços (ex.: `/spec levels-and-highscores`), ele é ambíguo entre descrição e slug — use-o como slug **e** como semente da descrição, sem pedir confirmação.

Se invocaram `/spec` sem argumentos, comece pedindo a descrição em uma frase.
