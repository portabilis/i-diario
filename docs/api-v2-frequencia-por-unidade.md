# API v2 — Consultas de frequência por unidade

## Visão geral

Cinco consultas de leitura, todas de frequência, para painéis externos que precisam dos números **como o i-Diário os apura** — sem recalcular falta nem definir régua própria. As regras de negócio da frequência vivem aqui; expor o dado pronto é o que impede o painel de mostrar um número e a notificação de infrequência do i-Diário mostrar outro.

| Rota | Parâmetros | Devolve |
|---|---|---|
| `GET /api/v2/infrequency_trackings` | `unity_api_code`, `start_at`, `end_at` | Notificações de infrequência apuradas pelo motor, com as datas das faltas |
| `GET /api/v2/student_absences` | `unity_api_code`, `start_at`, `end_at` | Dias de falta por estudante, com quantos lançamentos do dia têm justificativa |
| `GET /api/v2/general_configuration` | — | A régua de infrequência configurada pelo município |
| `GET /api/v2/unity_school_days` | `unity_api_code`, `start_at`, `end_at` | Os dias letivos da unidade no período |
| `GET /api/v2/frequency_record_completeness` | `unity_api_code`, `start_at`, `end_at` | Quanto do registro de frequência foi lançado, turma a turma |

## Autenticação

Header `token` com o `api_security_token` da configuração da API do i-Educar (**Configurações → API do i-Educar**). Token ausente ou inválido responde `401 {"errors": "Token inválido"}`.

## Fronteira de entrada (consultas por unidade e período)

As quatro consultas com `unity_api_code`, `start_at` e `end_at` validam a entrada antes de consultar qualquer coisa. Entrada inválida **nunca** vira coleção vazia — o consumidor não conseguiria distinguir de "não há dados".

| Situação | Resposta |
|---|---|
| Parâmetro ausente | `422 {"error": "Os seguintes parâmetros são obrigatórios: start_at, end_at"}` |
| `start_at`/`end_at` repetido | `422 {"error": "Os seguintes parâmetros aceitam um único valor: start_at"}` |
| Data fora de `AAAA-MM-DD` (inclui `31/06/2026` e `2026-13-01`) | `422 {"error": "Os parâmetros start_at e end_at devem estar no formato AAAA-MM-DD"}` |
| `start_at` depois de `end_at` | `422 {"error": "O parâmetro start_at deve ser anterior ou igual a end_at"}` |
| `unity_api_code` desconhecido | `200` com a coleção vazia — **não é erro**, ver abaixo |

`unity_api_code` aceita **uma ou várias** unidades — repita o parâmetro na forma de array:

```
?unity_api_code[]=2&unity_api_code[]=8&start_at=2026-06-01&end_at=2026-06-30
```

O período, esse é sempre um só.

**Unidade desconhecida responde `200` com coleção vazia, de propósito.** Quem consome varre a rede pela lista de escolas do i-Educar, e uma escola criada lá aparece na varredura antes de a sincronização criá-la aqui. Responder erro por causa dela derrubaria a varredura inteira — uma escola nova tiraria o painel do ar. Numa chamada com várias unidades, as conhecidas respondem normalmente e a desconhecida simplesmente não contribui.

A validação de formato (422) continua valendo: ela distingue *chamada malformada* de *unidade sem dados*, que é o que o `200 []` não conseguia dizer sozinho.

## `GET /api/v2/infrequency_trackings`

Uma linha por notificação que o motor de infrequência gerou (`InfrequencyTracking`), filtrada pela `notification_date` no período, da mais recente para a mais antiga.

```json
[
  {
    "student_api_code": "777",
    "registration_api_code": "999",
    "classroom_api_code": "12",
    "unity_api_code": "unity-1",
    "notification_type": "consecutive_absences",
    "notification_date": "2026-06-10",
    "absence_dates": ["2026-06-01", "2026-06-02", "2026-06-03"],
    "absences_count": 3
  }
]
```

- `notification_type`: `consecutive_absences` ou `alternate_absences`.
- `absence_dates`: datas distintas, ordenadas. O mesmo dia gravado por mais de um professor aparece uma vez.
- `registration_api_code`: a matrícula (`matricula_id` no i-Educar) do estudante naquela turma. Se o estudante saiu e voltou, vence a enturmação vigente na `notification_date`; sem nenhuma vigente, a mais recente. Nulo quando o estudante não tem matrícula na turma.
- `student_api_code`: nulo para estudante cadastrado localmente (sem código no i-Educar). Estudante unificado depois da notificação continua aparecendo, com o código dele.
- **Nada é agrupado.** A mesma ausência pode gerar duas notificações (régua das seguidas e das alternadas); unir as datas em episódios é papel de quem consome.

## `GET /api/v2/student_absences`

Uma entrada por estudante e turma, com os dias em que a **consolidação diária** marcou falta (`UniqueDailyFrequencyStudent`). É a mesma fonte que alimenta o motor de infrequência: se o dia consolidou como presente, ele não aparece aqui, mesmo com uma aula isolada ausente.

```json
[
  {
    "student_api_code": "777",
    "classroom_api_code": "12",
    "unity_api_code": "unity-1",
    "absences": [
      { "date": "2026-06-10", "entries_count": 2, "justified_entries_count": 1 },
      { "date": "2026-06-11", "entries_count": 1, "justified_entries_count": 0 }
    ]
  }
]
```

- `entries_count`: lançamentos de falta **ativos** do diário naquele dia (uma aula = um lançamento). Lançamento de quem já saiu da turma não conta, como na consolidação.
- `justified_entries_count`: quantos desses lançamentos têm justificativa vinculada. O fato vai cru — decidir se "1 de 2 justificadas" torna o dia justificado é régua de quem lê.
- **Zero** nos dois campos quando o dia consolidou como falta mas não há lançamento correspondente no diário (diário apagado depois da consolidação, por exemplo).
- Estudantes distintos nunca são fundidos, mesmo sem `student_api_code` (dois cadastros locais na mesma turma são duas entradas com código nulo).

## `GET /api/v2/general_configuration`

```json
{
  "notify_consecutive_or_alternate_absences": true,
  "max_consecutive_absence_days": 4,
  "max_alternate_absence_days": 6,
  "days_to_consider_alternate_absences": 10
}
```

- Com o aviso desligado (`notify_consecutive_or_alternate_absences: false`), os três limiares podem vir nulos: a rede não usa a régua, e quem lê não deve inventar um padrão.
- Rede **sem configuração cadastrada** responde `200` com os defaults de coluna (`notify_... = false` e os três limiares nulos), que é a forma do `GeneralConfiguration.current`.

## `GET /api/v2/unity_school_days`

```json
[
  {
    "unity_api_code": "unity-1",
    "school_days": ["2026-06-01", "2026-06-02", "2026-06-03"]
  }
]
```

Os dias letivos de cada **unidade** (`UnitySchoolDay`) no período, em ordem crescente, com uma entrada por unidade consultada. Unidade sem nenhum dia letivo no período não aparece na lista.

## `GET /api/v2/frequency_record_completeness`

Uma linha por turma da unidade, incluindo as que nunca lançaram — sumi-las esconderia justamente o caso que o indicador existe para mostrar.

```json
[
  {
    "classroom_api_code": "12",
    "classroom_name": "1º ANO A",
    "unity_api_code": "unity-1",
    "school_days": 20,
    "days_with_record": 17,
    "active_enrollments": 25
  }
]
```

- `school_days`: dias letivos da **unidade da turma** no período, no ano letivo dela — numa consulta com várias escolas, cada turma recebe o denominador da sua própria unidade. É a régua do Acompanhamento Pedagógico. Evento por turma, série ou curso não altera esse número; turma com calendário próprio recebe o corte da rede.
- `days_with_record`: dias distintos com **algum** lançamento de frequência na turma, por qualquer autor. Não verifica se todos os componentes do dia foram preenchidos.
- `active_enrollments`: matrículas com enturmação vigente em algum dia do período, contadas uma vez cada (turma multisseriada não duplica). Serve para descartar turma fantasma do cálculo.
- O percentual **não** é calculado aqui: `days_with_record / school_days` e o limiar de "em dia" são decisão de quem lê.
- Período que cruza o ano letivo (`2025-12-01..2026-02-28`) traz as turmas dos dois anos, cada uma com os dias letivos do seu próprio ano.

## Arquivos

- `app/controllers/concerns/api/v2/unity_period_params.rb` — fronteira de entrada compartilhada
- `app/controllers/api/v2/{infrequency_trackings,student_absences,general_configurations,unity_school_days,frequency_record_completeness}_controller.rb`
- `app/services/api/{infrequency_trackings,student_absences,unity_school_days,frequency_record_completeness}_service.rb`
- `app/models/infrequency_tracking.rb` — `#absence_dates`
