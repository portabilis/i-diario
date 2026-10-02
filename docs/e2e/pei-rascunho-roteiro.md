# Roteiro E2E: Rascunho do Plano Educacional Individualizado (PEI)

## Contexto

O PEI é preenchido num formulário de seis etapas.
Cada troca de etapa (Próxima, Anterior ou clique no título da etapa) salva o plano como rascunho, sem publicar versão.
O primeiro salvamento cria o plano e a tela passa a se comportar como a de edição, sem recarregar.
As datas previstas de revisão informadas na seção 1 definem os blocos das seções 4 e 5, e passam a valer nelas assim que o rascunho é salvo.
A versão do plano só é publicada no Finalizar da última etapa.

Na listagem, o plano aparece como "Em elaboração" enquanto o conteúdo atual não foi publicado e como "Finalizado" depois da publicação.
Um plano finalizado que recebe novo rascunho volta para "Em elaboração".

## Pré-requisitos

- Aplicação acessível na URL de `E2E_BASE_URL` e usuário válido no `.env.e2e`.
- O usuário é administrador ou servidor: professor não cria PEI.
- O perfil do usuário tem uma turma selecionada com ao menos um aluno cursando e sem PEI no ano letivo.
- A data de hoje é dia letivo no calendário da turma: a data de elaboração nasce com a data atual.
- A turma tem ao menos uma disciplina vinculada, para o cenário da seção 4.
- A integração de consulta dos dados do aluno responde: a finalização congela esses dados na versão.

O fluxo cria um PEI pela tela e o exclui no último cenário.
A exclusão arquiva o plano, então cada execução deixa um plano arquivado no banco usado.
Se um cenário intermediário falhar, o plano criado fica na listagem e precisa ser excluído manualmente.

## Cenários

### Happy Path

#### CT-02: Sair da seção 1 cria o rascunho e a revisão já aparece nas seções 4 e 5
- **Dado que** o usuário abriu um plano novo, escolheu um aluno sem PEI e informou uma data prevista de revisão
- **Quando** clica em Próxima
- **Então** a etapa 2 abre liberada, a URL passa a ser a de edição do plano criado, o rodapé mostra "Salvo às ..." e as seções 4 e 5 exibem a 1ª Revisão com a data informada

**Detalhes Técnicos:**
- URL inicial: `/planos-educacionais-individualizados/novo`; URL final: `/planos-educacionais-individualizados/<id>/editar`
- Aluno: `#s2id_individualized_educational_plan_student_id a.select2-choice` e `#select2-drop .select2-results li`
- Data de revisão: `#iep-review-dates input.datepicker`, digitada tecla a tecla (o campo tem máscara)
- Wait: resposta do `POST` com `draft=1`
- Assertions: `.iep-save-status-text` contém "Salvo às"; `#pei-step-4 .iep-review-buttons button` com o texto da revisão

#### CT-03: A disciplina adicionada na seção 4 é salva na troca de etapa, sem duplicar
- **Dado que** o rascunho existe e tem uma revisão
- **Quando** o usuário adiciona uma disciplina na seção 4, preenche a meta e vai para a seção 5
- **Então** o rascunho é salvo, e ao voltar para a seção 4 e ao recarregar a página existe uma única disciplina com a meta preenchida

**Detalhes Técnicos:**
- Seletores: `#pei-step-4 .iep-add-component`, `#s2id_iep-component-modal-select`, `#iep-component-modal-confirm`, `#pei-step-4 .iep-component-panel textarea`, `#pei-step-4 .iep-component-pills li`

#### CT-04: O rascunho aparece na listagem como "Em elaboração"
- **Dado que** o plano foi salvo só como rascunho
- **Quando** o usuário abre a listagem
- **Então** a linha do aluno mostra a situação "Em elaboração"

**Detalhes Técnicos:**
- URL: `/planos-educacionais-individualizados`
- Seletor: `#resources-tbody tr` com o nome do aluno, `.label`

#### CT-05: Finalizar publica a versão e a edição seguinte volta para "Em elaboração"
- **Dado que** o plano está em elaboração
- **Quando** o usuário finaliza na etapa 6 informando o nome da versão
- **Então** volta para a listagem com a situação "Finalizado"
- **E quando** edita o plano de novo e troca de etapa
- **Então** a listagem volta a mostrar "Em elaboração"

**Detalhes Técnicos:**
- Seletores: `.pei-wizard-finish`, `#version_name`, `#iep-finalize-confirm`

#### CT-06: Excluir o PEI pela listagem libera o aluno para um novo plano
- **Dado que** o plano do aluno está na listagem
- **Quando** o usuário exclui e confirma
- **Então** a linha do aluno sai da listagem

**Detalhes Técnicos:**
- Seletor: `a[data-method="delete"]` na linha do aluno; a confirmação é um diálogo do navegador

### Validações e Erros

#### CT-01: Plano novo sem aluno abre as etapas 2 a 6 travadas
- **Dado que** o usuário abriu um plano novo e não escolheu aluno
- **Quando** clica no título da etapa 2
- **Então** a etapa abre com os campos desabilitados e o aviso para selecionar o aluno e a data de elaboração
- **E quando** clica em "Ir para a seção 1"
- **Então** volta para a seção 1 e o aviso some

**Detalhes Técnicos:**
- Seletores: `#pei-wizard .steps li`, `.iep-locked-notice`, `.iep-go-to-identification`, `#pei-step-2 textarea`

#### CT-07: "Sim" em medicação sem medicamento mostra o motivo no topo da etapa
- **Dado que** o rascunho existe e o usuário está na etapa 3
- **Quando** responde "Sim" em "Faz uso de medicação?" sem informar medicamento e clica em outra etapa
- **Então** continua na etapa 3 e um alerta no topo da etapa, visível na tela, informa que falta ao menos um medicamento com nome
- **E quando** desfaz a resposta e clica em outra etapa
- **Então** a etapa troca e o alerta some

**Detalhes Técnicos:**
- Seletores: `#individualized_educational_plan_uses_medication`, `.iep-save-error`, `.iep-save-error-text`
- Wait: resposta 422 do `POST` com `draft=1`
- Assertion: `await expect(page.locator('.iep-save-error')).toBeInViewport()`

## Autovalidação do roteiro

| Comportamento | Cenário |
| --- | --- |
| A troca de etapa salva os dados | CT-02, CT-03 |
| Sem aluno a navegação funciona e um aviso é exibido | CT-01 |
| Depois do primeiro salvamento a tela fica no plano, em edição | CT-02 |
| Salvamentos seguintes não duplicam registros filhos | CT-03 |
| Datas de revisão da seção 1 aparecem nas seções 4 e 5 sem recarregar | CT-02 |
| Rascunho "Em elaboração"; finalizado "Finalizado" | CT-04, CT-05 |
| O indicador de salvamento mostra sucesso e a recusa aparece em local visível | CT-02, CT-03, CT-07 |

Fora deste roteiro, por serem cobertos por testes de unidade ou por dependerem de condição que a tela não reproduz de forma determinística:

- Falha de conexão com nova tentativa, recusa do servidor e linhas inalteradas fora do envio (Jest do módulo de rascunho).
- Confirmação ao remover data de revisão com conteúdo (Jest do formulário).
- Aluno que já possui PEI, aluno que não cursa mais a turma e edição pelo professor (specs de controller).
