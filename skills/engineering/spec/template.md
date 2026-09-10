# Template de uma spec útil

Este arquivo é a referência que a skill `/spec` consulta ao gerar specs. Cada seção inclui o seu propósito e um exemplo mínimo. **Não é texto para ser copiado ao pé da letra** — é a forma que a skill precisa respeitar.

---

## Cabeçalho

Toda spec começa com metadados em um blockquote (sem tabelas, sem blocos, simples como mostrado abaixo):

```markdown
# SPEC NN — Título curto e descritivo

> **Status:** Rascunho
> **Depende de:** SPEC 01, SPEC 02
> **Data:** AAAA-MM-DD
> **Objetivo:** Uma única frase. Se você precisa de duas, a feature é grande demais.
```

**Estados válidos:** `Rascunho`, `Em revisão`, `Aprovado`, `Implementado`, `Obsoleto`.

> Os rótulos acima são os padrões em português. As skills também aceitam equivalentes em qualquer idioma (ex.: inglês `Draft` / `In review` / `Approved` / `Implemented` / `Obsolete`). Escolha um conjunto por repositório e mantenha a consistência.

**Regra do objetivo:** uma frase que um humano lê em 5 segundos e entende o que vai ser construído. Se não couber em uma frase, divida a feature.

---

## Seção 1 — Por que esta spec existe (opcional)

Para specs que tomam decisões não óbvias ou quebram padrões do projeto, uma seção breve explicando o **porquê** do trabalho. Não o quê — o quê vem depois.

Para specs simples, omita.

---

## Seção 2 — Escopo

Dois sub-blocos explícitos. **Ambos são obrigatórios.**

```markdown
## Escopo

**Dentro:**

- Coisa concreta um.
- Coisa concreta dois.

**Fora do escopo (para specs futuras):**

- Algo que poderia ser feito mas não agora.
- Algo que apareceu na conversa mas não entra.
```

**Por que o "fora" importa:** ele captura as coisas que o usuário mencionou durante a fase de perguntas mas foram decididas como adiadas. Sem esse registro, durante a implementação vai existir a tentação de encaixá-las "já que estamos aqui".

---

## Seção 3 — Modelo de dados

As estruturas concretas que aparecem ou mudam. Use código real, não pseudocódigo abstrato.

```markdown
## Modelo de dados

\`\`\`js
// Estado do jogo
const state = {
level: 1,
score: 0,
highScores: [/* { score, level, date } */],
};
\`\`\`

Convenções:

- Coordenadas: origem no canto superior esquerdo.
- Velocidades em pixels/frame.
```

Se a feature não introduz dados novos, escreva isso explicitamente: _"Esta feature não introduz novas estruturas de dados. Ela reutiliza o modelo da SPEC 01."_

---

## Seção 4 — Plano de implementação

Passos numerados. Cada passo deve deixar o sistema em estado **funcional e executável**. Nada de "implemento metade e continuo amanhã".

```markdown
## Plano de implementação

1. Crie o arquivo X com um esqueleto vazio.
2. Implemente a função A em X, com os testes de comportamento e de erro.
3. Ligue X ao módulo W existente. Teste manual: rode Y, veja Z.
4. ...
```

**Regras:**

- Cada passo precisa ser commitável sozinho.
- **Cada passo que introduz comportamento traz o teste junto** — um passo sem o teste dele não está concluído (ver a skill `unit-testing-standards`).
- Se um passo exige mais de 30–50 linhas de código, divida.
- O último passo do plano **não** é "testar tudo" — isso são os critérios de aceite.

---

## Seção 5 — Critérios de aceite

Checklist booleano. Cada item pode ser verificado com sim ou não.

```markdown
## Critérios de aceite

- [ ] O jogo carrega sem erros no console.
- [ ] Quebrar um tijolo soma exatamente 10 pontos.
- [ ] Recarregar a página preserva os recordes.
- [ ] A suíte passa por inteiro, incluindo os testes novos de pontuação.
```

**Regra extra:** todo checklist de aceite tem **um item verificável de testes**. `A suíte passa por inteiro` é verificável; `tem testes` não é (não dá para responder sim ou não).

**Anti-padrões a evitar:**

- ❌ "Que funcione bem." → não é verificável.
- ❌ "Boa UX." → subjetivo.
- ❌ "Sem bugs." → não é operacional.
- ❌ "Cobertura melhorou." → não é verificável.
- ✅ "Apertar Esc pausa o jogo e mostra o menu." → verificável, booleano.

---

## Seção 6 — Decisões tomadas e descartadas

A seção com mais valor daqui a 3 meses. Registre **o que você considerou**, não só o que escolheu.

```markdown
## Decisões

- **Sim:** localStorage para persistência. Cabe em <5MB e não precisamos de consultas.
- **Não:** IndexedDB. Overengineering para este caso.
- **Sim:** chave versionada (`save:v1`). Permite migrar o schema depois sem quebrar.
- **Não:** sincronização na nuvem. Vai em outra spec se um dia acontecer.
```

Idealmente cada decisão tem uma razão breve. Decisões sem razão são as primeiras a serem questionadas depois.

---

## Seção 7 — Riscos identificados (opcional)

Apenas quando existem riscos não óbvios. Tabela simples:

```markdown
## Riscos

| Risco                                     | Mitigação                                                       |
| ----------------------------------------- | --------------------------------------------------------------- |
| localStorage desabilitado no modo privado | Fallback para objeto em memória. O jogo roda, só não persiste.  |
| Schema futuro incompatível                | A chave inclui `:v1`. Migração documentada em `persistence.js`. |
```

Para specs pequenas ou features muito contidas, omita.

---

## Seção final — O que NÃO está (reforço)

Repita explicitamente no final o que **não** será feito nesta spec. Essa repetição é deliberada — a seção de Escopo já diz isso, mas no fim do documento ela serve de lembrete para quem lê só as últimas linhas.

```markdown
## O que **não** está nesta spec

- Editor visual (outra spec se um dia acontecer).
- Multiplayer.
- Versão mobile.

Cada um desses, se um dia acontecer, vai em uma spec própria.
```

---

## Regras globais sobre o documento inteiro

- **Uma frase por ideia.** Se uma frase tem duas vírgulas e um ponto e vírgula, divida.
- **Nomes concretos.** Se você diz "o módulo de fases", diga `src/levels.js`. Se você diz "uma chave", dê a string exata.
- **Sem TODOs.** Um TODO em uma spec significa que a decisão não foi tomada. Tome-a ou registre como decisão pendente com uma razão.
- **Sem código executável longo.** A spec descreve; o código é escrito depois. Trechos curtos para ilustrar estruturas de dados são aceitáveis; funções completas não.
- **Markdown padrão.** Sem extensões estranhas. Precisa renderizar no GitHub sem surpresas.
