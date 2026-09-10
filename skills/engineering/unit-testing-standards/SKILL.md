---
name: unit-testing-standards
description: Exige teste automatizado para todo código com comportamento e diz como escrevê-lo — vale para backend, frontend, worker, CLI e biblioteca. Use sempre que criar ou alterar código, antes de dar uma entrega por concluída, ou ao revisar um PR sem testes. Cobre o que sempre precisa de teste, o que é isento, como montar a trava determinística (script + hook + CI) e como escrever o teste (AAA, mock só nas fronteiras).
---

# unit-testing-standards — Teste obrigatório para código com comportamento

## Contexto da sessão

Manifestos encontrados (indicam como os testes rodam):
!`ls package.json pyproject.toml go.mod Cargo.toml pom.xml Gemfile composer.json 2>/dev/null || echo "nenhum manifesto reconhecido"`

Testes que já existem (use como padrão de estilo do projeto):
!`git ls-files -- '*.test.*' '*.spec.*' '*_test.go' 'test_*.py' '*Test.java' '*Tests.cs' 2>/dev/null | head -5 | grep . || echo "Nenhum teste encontrado no repositório"`

Trava instalada neste projeto?
!`ls .github/hooks/check-test-pairs.sh 2>/dev/null || echo "Trava não instalada (ver seção 5)"`

---

## 1. A regra

**Nenhuma entrega está concluída enquanto o comportamento novo não tiver teste automatizado.** Não é "quando der tempo", não é "o teste vai no próximo PR". O teste é parte da mudança, igual ao código — e isso vale para qualquer stack: frontend, backend, worker, CLI, biblioteca, script de migração.

Duas consequências práticas:

- Quem escreve o código escreve o teste, na mesma entrega.
- Um passo do plano (ou uma task) que introduz comportamento **não** está concluído sem o teste — ver [seção 6](#6-checklist-antes-de-dar-por-concluído).

Se o projeto ainda não tem runner de teste configurado, **configurar isso é o primeiro passo**, antes do primeiro teste.

---

## 2. O que sempre precisa de teste

O critério é **comportamento**, não pasta. A lista vale igual em qualquer linguagem — só mudam os nomes:

| Categoria                    | Onde costuma aparecer                                                  |
| ---------------------------- | ---------------------------------------------------------------------- |
| Regra de negócio / cálculo   | total, desconto, imposto, cálculo de horário, ordenação, pontuação     |
| Transformação / mapeamento   | mapper entre DTO e entidade, serializer, parse de payload              |
| Validação                    | schema, formulário, sanitização de entrada                             |
| Caso de borda e erro         | entrada vazia, limite, valor negativo, conflito, timeout, 404          |
| Contrato com o mundo externo | chamada HTTP, repositório, fila, cache — com o cliente mockado         |
| Orquestração                 | service, use case, handler, controller, Server Action, hook com lógica |
| Ramificação de UI            | componente que decide o que renderizar a partir de estado/props        |

Regra prática: **se você consegue descrever um comportamento e o resultado esperado em uma frase, isso é um teste.** Se não consegue, provavelmente ainda não está claro o que a mudança entrega.

---

## 3. O que é isento

Isenção existe, mas precisa ser explícita e revisável. São isentos por natureza:

- Declaração de tipos/interfaces, enums e constantes.
- Configuração e bootstrap (wiring de dependências, `main`).
- Barrels e re-exports.
- Código gerado, migração de banco, seed, fixture.
- Componente puramente visual: sem ramificação, sem estado e sem cálculo (um container que só recebe `children` não tem comportamento).
- Wrapper fino sobre biblioteca de terceiros, sem regra própria.

Nada além disso. E quando um arquivo isento por natureza ainda cair na trava, a saída **não** é afrouxar a trava: é marcar o arquivo com `test-ignore: <motivo>` (ver seção 5), para a exceção ficar visível em review — em vez de escondida na configuração.

---

## 4. Como escrever

- **Arrange / Act / Assert.** Um comportamento por teste. Se o nome do teste precisa de um "e", provavelmente são dois testes.
- **O nome descreve comportamento, não método.** `deve recusar agendamento quando o horário já está ocupado` vale mais que `testCreate`.
- **Mock nas fronteiras, nunca no código sob teste.** Rede, banco, relógio, aleatoriedade e filesystem são mockados. A função que você está testando, não.
- **Determinismo.** Nada de depender de `Date.now()`, de ordem de execução ou de estado compartilhado entre testes. Tempo e id entram como parâmetro ou são congelados no teste.
- **Teste o que pode quebrar.** Cobrir o caminho de erro vale mais do que cobrir getter. Um teste que passa sempre (snapshot gigante, asserção genérica tipo "é truthy") não é teste.
- **Sem acoplar a detalhe interno.** Se renomear uma variável privada quebra o teste, o teste está acoplado demais.
- **Um arquivo de teste por arquivo de código**, ao lado dele, com o sufixo do runner: `x.ts` → `x.test.ts`, `x.go` → `x_test.go`, `x.py` → `test_x.py`, `Foo.java` → `FooTest.java`. Não crie uma árvore paralela de testes.

---

## 5. A trava

Regra em skill **orienta**; não **bloqueia**. Se você precisa de garantia, ela tem que estar em código — a mesma lógica de autorização, que não se resolve só escondendo o botão na UI. Três camadas, nenhuma substitui a outra:

| Camada        | O que é                      | Garantia                                            |
| ------------- | ---------------------------- | --------------------------------------------------- |
| Esta skill    | Instrução                    | Orienta. O agente pode esquecer.                    |
| Script + hook | Verificação no fim da sessão | **Bloqueia** enquanto houver arquivo sem teste.     |
| CI            | Job obrigatório              | Autoridade final: vale até para commit feito à mão. |

### 5.1 O script

O companheiro desta skill, `scripts/check-test-pairs.sh`, verifica se cada arquivo de código alterado tem teste:

```bash
# o que está modificado/novo na árvore de trabalho
bash check-test-pairs.sh

# tudo o que a branch adicionou em relação à main
bash check-test-pairs.sh --base origin/main

# todos os arquivos versionados (auditoria)
bash check-test-pairs.sh --all
```

Sai com `0` quando está coberto e `2` quando falta teste. Ele:

- ignora por caminho o que é isento (tipos, enums, constantes, config, migrações, seeds, fixtures, gerados, stories, mocks);
- reconhece as convenções de nome de teste de TS/JS, Go, Python, Java, Kotlin, C#, Ruby e PHP;
- aceita exceção consciente: um arquivo com `test-ignore: <motivo>` nas 10 primeiras linhas é pulado;
- aceita ajuste por ambiente: `SRC_ROOT_RE` (diretórios que exigem teste) e `EXEMPT_RE` (caminhos isentos), ambos regex estendida.

### 5.2 O hook (trava local)

Copie o script para o projeto e registre o hook de fim de sessão. `<pasta-da-skill>` é onde esta skill está instalada (ex.: `~/.claude/skills/unit-testing-standards` ou `.claude/skills/unit-testing-standards`).

> No Cursor, só o corpo desta skill vira regra em `.cursor/rules/` — os arquivos companheiros (`scripts/` e `hooks/`) não são copiados pelo instalador. Nesse caso, pegue-os do repositório clonado (ex.: `~/.skills/skills/engineering/unit-testing-standards/`).

```bash
mkdir -p .github/hooks
cp <pasta-da-skill>/scripts/check-test-pairs.sh .github/hooks/
chmod +x .github/hooks/check-test-pairs.sh
cp <pasta-da-skill>/hooks/verify-tests.json .github/hooks/
```

O `verify-tests.json` roda o script no evento `Stop`. Se faltar teste, o agente **não encerra** a sessão sem resolver — é o equivalente a "não dá para entregar sem teste" dentro do editor. Se o hook não encontrar o script, use caminho absoluto no campo `command`.

### 5.3 O CI (autoridade)

Um passo no workflow do projeto, para valer independentemente de quem escreveu o código:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0 # a trava precisa do histórico para achar o merge-base

- name: Testes obrigatórios
  run: |
    bash .github/hooks/check-test-pairs.sh --base origin/${{ github.base_ref }}
    npm test
```

Troque `npm test` pelo comando do projeto (`go test ./...`, `pytest`, `./gradlew test`).

Com clone raso (`fetch-depth: 1`, o padrão do checkout) a ref base não existe e o script sai com `1` em vez de passar em silêncio — de propósito: uma trava mal configurada que passa é pior do que não ter trava, porque dá falsa sensação de cobertura.

---

## 6. Checklist antes de dar por concluído

- [ ] Todo arquivo com comportamento novo ou alterado tem teste irmão.
- [ ] O caminho de erro está coberto, não só o caminho feliz.
- [ ] Só existem mocks de fronteira (rede, banco, tempo, aleatoriedade).
- [ ] A suíte passa por inteiro, não só o arquivo novo.
- [ ] Todo arquivo sem teste tem `test-ignore: <motivo>` ou está na lista de isentos da seção 3.
- [ ] `check-test-pairs.sh` sai com `0`.

Se algum item não fecha, a entrega não está pronta — o próximo passo não é "commitar e resolver depois".
