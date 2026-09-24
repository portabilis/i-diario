<!--- O título deve dizer o que muda, em uma linha. O resumo vai na seção abaixo. -->

## Resumo
<!---
O que um revisor precisa saber em 30 segundos, antes de abrir o diff.
3 a 5 linhas, em linguagem de produto: o que muda para quem usa, e como.
O detalhe técnico fica nas seções abaixo — aqui é só o suficiente para ele
decidir por onde começar a revisão.
-->

---

## Descrição
<!---
As decisões técnicas e o caminho de leitura ("comece por X, o resto é consequência").
Não liste os arquivos alterados: eles estão no diff.
-->

## Contexto e motivação
<!---
Por que a alteração foi necessária e o que o revisor não descobre lendo o diff:
a regra de negócio, a restrição do schema, as alternativas descartadas.
Fecha uma issue? Use: Closes portabilis/board#numero
-->

## Tipos de alterações
<!--- Remova todas as linhas que não foram aplicadas. -->
- ✅ Correção de bugs (Não quebra outras funcionalidades)
- ✅ Nova feature (Não quebra outras funcionalidades e adiciona funcionalidades)
- ✅ Alteração com alto impacto (Correção ou mudança, pode quebrar parte da aplicação)

## Impacto e riscos
<!---
Migração de dados, mudança de contrato de API, ordem de deploy, efeito em performance,
o que quebra se algo der errado e como reverter.
Sem risco relevante? Escreva "Nenhum" — silêncio é indistinguível de não ter avaliado.
-->

## Checklist:
<!--- Remova todas as linhas que não foram aplicadas. -->

- ✅ Meu código segue o style guide do **CONTRIBUTING**. **[REQUIRED]**
- ✅ Todos os testes novos e existentes estão passando. **[REQUIRED]**
- ✅ Criei testes que cobrem minhas alterações.
- ✅ Code review agêntico executado (`/cr-1` + `/cr-2` + `/cr-consolidate`) e findings endereçados/justificados (ver [docs/code-review-agentico.md](../docs/code-review-agentico.md)).
