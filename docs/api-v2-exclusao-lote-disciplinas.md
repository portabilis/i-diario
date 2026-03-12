# API v2 — Exclusão em Lote de Registros de Disciplinas

## Visão Geral

Quando um usuário precisa remove componentes curriculares (disciplinas) de séries diretamente na tela do i-Educar, e essas disciplinas já possuem lançamentos no i-Diário (frequências, avaliações, planos de aula, etc.), o i-Educar consome esta API para excluir em lote todos os registros vinculados no i-Diário. Todo o fluxo é iniciado e confirmado pelo usuário na interface do i-Educar.

A API opera em **3 etapas**: contagem (prévia), enfileiramento (assíncrono) e callback (notificação).

---

## Fluxo Geral

```mermaid
sequenceDiagram
    participant Usuário
    participant iEducar as i-Educar
    participant API as i-Diário API v2
    participant Sidekiq as Sidekiq Worker
    participant DB as Banco de Dados

    Usuário->>iEducar: Remove disciplina de uma série
    iEducar->>API: POST /api/v2/discipline_records/count
    Note over API: Valida token + 5 parâmetros obrigatórios
    API->>DB: Consulta registros por tipo (11 tipos)
    DB-->>API: Contagens
    API-->>iEducar: Array com label + count por tipo
    iEducar-->>Usuário: Exibe prévia: "42 frequências, 10 avaliações..."

    Usuário->>iEducar: Confirma exclusão
    iEducar->>API: POST /api/v2/discipline_records/destroy_batch
    Note over API: Valida token + 6 parâmetros (filtros + user + callback_url)
    API->>DB: Cria DisciplineRecordDeletion (status: processing)
    API->>Sidekiq: Enfileira DisciplineRecordsDestroyerWorker
    API-->>iEducar: { queued: true }

    rect rgb(255, 240, 240)
        Note over Sidekiq,DB: Processamento assíncrono (transação)
        Sidekiq->>DB: Captura snapshot JSON de todos os registros
        Sidekiq->>DB: Exclui registros em ordem de FK
        Sidekiq->>DB: Salva snapshots em discipline_record_deletion_postings
        Sidekiq->>DB: Cria audits com username identificando operação + usuário
        Sidekiq->>DB: Atualiza deletion (status: completed, total_deleted: N)
    end

    alt Sucesso
        Sidekiq->>iEducar: POST callback_url { success: true, deleted: 97 }
        iEducar-->>Usuário: "97 registros excluídos com sucesso"
    else Erro
        Note over Sidekiq,DB: Rollback automático
        Sidekiq->>DB: Atualiza deletion (status: error, error_message)
        Sidekiq->>iEducar: POST callback_url { success: false, error: "mensagem" }
        iEducar-->>Usuário: Exibe erro (nenhum registro foi excluído)
    end
```

---

## Arquitetura Interna

```mermaid
flowchart TB
    Controller["DisciplineRecordsController"]
    Worker["DisciplineRecordsDestroyerWorker<br/><i>Sidekiq (assíncrono)</i>"]

    subgraph Services ["Service Objects"]
        Query["DisciplineRecordsQuery<br/><i>Resolve filtros em IDs internos</i>"]
        Counter["DisciplineRecordsCounter<br/><i>Conta registros por tipo</i>"]
        Destroyer["DisciplineRecordsDestroyer<br/><i>Exclui em ordem de FK</i>"]
    end

    subgraph Rastreabilidade
        Deletion["discipline_record_deletions<br/><i>1 registro por execução</i>"]
        Postings["discipline_record_deletion_postings<br/><i>Snapshot JSON completo por tipo</i>"]
        Audits["audits (Audited)<br/><i>Audit trail vinculado à operação</i>"]
    end

    Controller -- "POST /count" --> Counter
    Controller -- "POST /destroy_batch" --> Worker
    Worker --> Destroyer
    Worker -- "POST callback_url" --> Callback["i-Educar (callback)"]
    Counter --> Query
    Destroyer --> Query
    Destroyer --> Deletion
    Destroyer --> Postings
    Destroyer -- "Audited.as_user" --> Audits
```

---

## Resolução de Filtros (Query)

```mermaid
flowchart LR
    subgraph Entrada ["Parâmetros (api_codes do i-Educar)"]
        Year["year"]
        Unities["unities"]
        Courses["courses"]
        Grades["grades"]
        Disciplines["disciplines"]
    end

    subgraph Resolução ["Resolução de IDs"]
        UnityIDs["unity_ids<br/>Unity.where(api_code:)"]
        CourseIDs["course_ids<br/>Course.where(api_code:)"]
        GradeIDs["grade_ids<br/>Grade.where(api_code:)<br/><i>Infere do course se vazio</i>"]
        DisciplineIDs["discipline_ids<br/>Discipline.where(api_code:)"]
        ClassroomIDs["classroom_ids<br/>ClassroomsGrade.joins(:classroom)<br/>.where(year:, grade_id:, unity_id:)"]
    end

    subgraph Calendario ["Data de Início"]
        CalClassroom["SchoolCalendarClassroom<br/><i>Calendário próprio da turma</i>"]
        CalSchool["SchoolCalendar<br/><i>Calendário da escola (fallback)</i>"]
    end

    Unities --> UnityIDs
    Courses --> CourseIDs
    Grades --> GradeIDs
    CourseIDs -.-> GradeIDs
    Disciplines --> DisciplineIDs
    Year --> ClassroomIDs
    UnityIDs --> ClassroomIDs
    GradeIDs --> ClassroomIDs
    ClassroomIDs --> CalClassroom
    ClassroomIDs --> CalSchool

    CalClassroom --> Scope["Scope final:<br/>WHERE classroom_id IN (...)<br/>AND discipline_id IN (...)<br/>AND date >= start_at"]
    CalSchool --> Scope
    DisciplineIDs --> Scope
```

---

## Ordem de Exclusão (Destroyer)

A exclusão segue uma ordem específica para respeitar as foreign keys do banco. Antes de cada exclusão, o destroyer captura um snapshot JSON completo dos atributos de todos os registros (pais e filhos) para possibilitar restauração.

```mermaid
flowchart TB
    subgraph Step1 ["1. Avaliações e filhos"]
        direction TB
        ARD1["AvaliationRecoveryDiaryRecord"]
        DNS["DailyNoteStudent<br/><i>(with_discarded)</i>"]
        DN["DailyNote"]
        AE["AvaliationExemption<br/><i>(with_discarded)</i>"]
        AV["Avaliation"]
        AG["AvaliationsGrade<br/><i>(HABTM, snapshot via SQL)</i>"]
        ARD1 --> DN
        DNS --> DN
        DN --> AV
        AE --> AV
        AG --> AV
    end

    subgraph Step2 ["2. Exames conceituais"]
        direction TB
        CEV["ConceptualExamValue<br/><i>(filtra por discipline_id)</i>"]
        CE["ConceptualExam<br/><i>(só órfãos, with_discarded)</i>"]
        CEV --> CE
    end

    subgraph Step3 ["3. Recuperações e filhos"]
        direction TB
        RDRS["RecoveryDiaryRecordStudent<br/><i>(with_discarded)</i>"]
        STRD["SchoolTermRecoveryDiaryRecord"]
        FRD["FinalRecoveryDiaryRecord"]
        ARD2["AvaliationRecoveryDiaryRecord"]
        ARLN["AvaliationRecoveryLowestNote"]
        RDR["RecoveryDiaryRecord"]
        RDRS --> RDR
        STRD --> RDR
        FRD --> RDR
        ARD2 --> RDR
        ARLN --> RDR
    end

    subgraph Step4 ["4. Frequências"]
        direction TB
        DFS["DailyFrequencyStudent<br/><i>(with_discarded, explícito)</i>"]
        DF["DailyFrequency"]
        DFS --> DF
    end

    subgraph Step5 ["5. Registros de conteúdo"]
        direction TB
        CRC["ContentRecordsContent"]
        CR["ContentRecord"]
        DCR["DisciplineContentRecord"]
        CRC --> CR
        CR --> DCR
    end

    subgraph Step6 ["6. Planos de aula"]
        direction TB
        CLP["ContentsLessonPlan"]
        OLP["ObjectivesLessonPlan"]
        LPA["LessonPlanAttachment"]
        LP["LessonPlan"]
        DLP["DisciplineLessonPlan"]
        CLP --> LP
        OLP --> LP
        LPA --> LP
        LP --> DLP
    end

    subgraph Step7 ["7. Planos de ensino"]
        direction TB
        CTP["ContentsTeachingPlan"]
        OTP["ObjectivesTeachingPlan"]
        TPA["TeachingPlanAttachment"]
        TP["TeachingPlan"]
        DTP["DisciplineTeachingPlan"]
        CTP --> TP
        OTP --> TP
        TPA --> TP
        TP --> DTP
    end

    subgraph Step8 ["8. Observações e filhos"]
        direction TB
        ODRNS["ObservationDiaryRecordNoteStudent<br/><i>(with_discarded)</i>"]
        ODRN["ObservationDiaryRecordNote<br/><i>(with_discarded)</i>"]
        ODRA["ObservationDiaryRecordAttachment"]
        ODR["ObservationDiaryRecord"]
        ODRNS --> ODRN
        ODRN --> ODR
        ODRA --> ODR
    end

    subgraph Step9 ["9. Exames complementares"]
        direction TB
        CES["ComplementaryExamStudent<br/><i>(with_discarded)</i>"]
        CEX["ComplementaryExam"]
        CES --> CEX
    end

    subgraph Step10 ["10. Exames descritivos"]
        direction TB
        DES["DescriptiveExamStudent<br/><i>(with_discarded)</i>"]
        DEX["DescriptiveExam"]
        DES --> DEX
    end

    subgraph Step11 ["11. Notas de transferência"]
        direction TB
        TNDNS["DailyNoteStudent<br/><i>(snapshot antes do callback<br/>que nullifica transfer_note_id e note)</i>"]
        TN["TransferNote<br/><i>(seta step_id antes do destroy)</i>"]
        TNDNS -.-> TN
    end

    Step1 --> Step2 --> Step3 --> Step4 --> Step5 --> Step6 --> Step7 --> Step8 --> Step9 --> Step10 --> Step11
```

---

## Rastreabilidade e Restauração

### Tabelas de controle

Cada execução do `destroy_batch` cria registros para rastreabilidade:

| Tabela | Descrição | Exemplo |
|--------|-----------|---------|
| `discipline_record_deletions` | 1 registro por execução com filtros, usuário e total | `filters: {year: 2025, unities_api_code: ["2"], user_api_code: "1"}, total_deleted: 97` |
| `discipline_record_deletion_postings` | Snapshot JSON completo dos atributos por tipo de record | `record_type: 'DailyFrequency', records_data: [{id: 101, classroom_id: 5, ...}, ...]` |
| `audits` (Audited) | Audit trail vinculado à operação | `username: 'discipline_record_deletion_id:1:ieducar_user:1'` |

### Snapshot JSON

O destroyer captura os **atributos completos** (`.attributes`) de cada registro antes de destruí-lo. Isso inclui:

- Todos os campos do registro (incluindo FKs que a gem Audited exclui via `audited except:`)
- Join tables HABTM sem model (`avaliations_grades`) via SQL direto
- Filhos com `dependent: :destroy` que seriam perdidos em cascata (`ContentRecord`, `LessonPlan`, `TeachingPlan` e todos os seus filhos)
- `DailyNoteStudent` vinculados a `TransferNote` (que o callback `before_destroy` nullifica antes da exclusão)
- Records soft-deleted via `with_discarded` para capturar registros descartados

**Total: 33 record types capturados** em 11 steps de exclusão.

### Record types capturados por step

| Step | Record types no snapshot |
|------|------------------------|
| Avaliações | `Avaliation`, `AvaliationRecoveryDiaryRecord`, `DailyNote`, `DailyNoteStudent`, `AvaliationExemption`, `AvaliationsGrade` |
| Exames conceituais | `ConceptualExamValue`, `ConceptualExam` |
| Recuperações | `RecoveryDiaryRecord`, `RecoveryDiaryRecordStudent`, `SchoolTermRecoveryDiaryRecord`, `FinalRecoveryDiaryRecord`, `AvaliationRecoveryDiaryRecord`, `AvaliationRecoveryLowestNote` |
| Frequências | `DailyFrequency`, `DailyFrequencyStudent` |
| Registros de conteúdo | `DisciplineContentRecord`, `ContentRecord`, `ContentRecordsContent` |
| Planos de aula | `DisciplineLessonPlan`, `LessonPlan`, `ContentsLessonPlan`, `ObjectivesLessonPlan`, `LessonPlanAttachment` |
| Planos de ensino | `DisciplineTeachingPlan`, `TeachingPlan`, `ContentsTeachingPlan`, `ObjectivesTeachingPlan`, `TeachingPlanAttachment` |
| Observações | `ObservationDiaryRecord`, `ObservationDiaryRecordNote`, `ObservationDiaryRecordNoteStudent`, `ObservationDiaryRecordAttachment` |
| Exames complementares | `ComplementaryExam`, `ComplementaryExamStudent` |
| Exames descritivos | `DescriptiveExam`, `DescriptiveExamStudent` |
| Notas de transferência | `TransferNote`, `TransferNoteDailyNoteStudent` |

### Limpeza automática de dados antigos

A rake task `discipline_records:cleanup_old_deletions` remove registros de rastreabilidade que não são mais necessários.

**Critério de limpeza:** `year <= ano_anterior` **E** `created_at < 1 mês atrás`

Exemplo: executada em 11/03/2026, remove deletions com `year <= 2025` e `created_at < 11/02/2026`.

```bash
# Execução manual:
docker compose exec puma bundle exec rake discipline_records:cleanup_old_deletions

# Cron sugerido (1x por mês, dia 1 às 03:00):
0 3 1 * * cd /app && bundle exec rake discipline_records:cleanup_old_deletions
```

---

## Endpoints

### POST `/api/v2/discipline_records/count`

Retorna a contagem de registros que seriam afetados pelos filtros.

**Headers:**
| Header | Descrição |
|--------|-----------|
| `token` | `api_security_token` do `IeducarApiConfiguration` |

**Body (JSON):**
```json
{
  "year": 2025,
  "unities": ["5"],
  "courses": ["22"],
  "grades": ["51", "52"],
  "disciplines": ["10", "15"]
}
```

**Resposta (200):**
```json
[
  { "label": "Frequências diárias", "count": 42 },
  { "label": "Avaliações numéricas", "count": 10 },
  { "label": "Avaliações conceituais", "count": 3 },
  { "label": "Recuperações", "count": 5 },
  { "label": "Registros de conteúdo", "count": 8 },
  { "label": "Planos de aula", "count": 4 },
  { "label": "Planos de ensino", "count": 2 },
  { "label": "Diário de observações", "count": 6 },
  { "label": "Notas de transferência", "count": 1 },
  { "label": "Exames complementares", "count": 3 },
  { "label": "Avaliações descritivas", "count": 0 }
]
```

### POST `/api/v2/discipline_records/destroy_batch`

Enfileira a exclusão dos registros no Sidekiq e retorna imediatamente. O resultado é enviado via callback HTTP ao i-Educar.

**Body (JSON):** Mesmo do `count` + campos `user` e `callback_url`:
```json
{
  "year": 2025,
  "unities": ["5"],
  "courses": ["22"],
  "grades": ["51", "52"],
  "disciplines": ["10", "15"],
  "user": "1",
  "callback_url": "https://ieducar.example.com/webhook/component-batch/42"
}
```

**Resposta (200):**
```json
{ "queued": true }
```

**Resposta (422):**
```json
{ "success": false, "errors": "Parâmetros obrigatórios ausentes: ..." }
```

**Callback (POST para callback_url):**

Quando o worker finaliza, envia um POST para a `callback_url` com header `token` (api_security_token) e body:
```json
// Sucesso
{ "success": true, "deleted": 97 }

// Erro
{ "success": false, "error": "mensagem de erro" }
```

### Validações

| Cenário | Status | Resposta |
|---------|--------|----------|
| Sem header `token` | 401 | `{ "errors": "Token inválido" }` |
| Token incorreto | 401 | `{ "errors": "Token inválido" }` |
| Parâmetros ausentes (count) | 422 | `{ "success": false, "errors": "Parâmetros obrigatórios ausentes: year, unities, ..." }` |
| Parâmetros ausentes (destroy_batch) | 422 | `{ "success": false, "errors": "Parâmetros obrigatórios ausentes: year, ..., user" }` |
| Filtros sem correspondência | 200 | `{ "queued": true }` (callback retorna `deleted: 0`) |
| Erro na exclusão | 200 | `{ "queued": true }` (callback retorna `success: false`) |

---

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `year` | Sim | Ano letivo |
| `unities` | Sim | Array de `api_codes` das escolas no i-Educar |
| `courses` | Sim | Array de `api_codes` dos cursos |
| `grades` | Sim | Array de `api_codes` das séries |
| `disciplines` | Sim | Array de `api_codes` das disciplinas |
| `user` | Sim (destroy_batch) | `api_code` do usuário que executou a operação |
| `callback_url` | Não | URL para receber o resultado via POST quando o processamento finalizar |

---

## Tipos de Registro Cobertos

| # | Tipo | Model principal | Filhos excluídos / capturados |
|---|------|----------------|-------------------------------|
| 1 | Avaliações numéricas | `Avaliation` | `AvaliationRecoveryDiaryRecord`, `DailyNote`, `DailyNoteStudent`, `AvaliationExemption`, `AvaliationsGrade` |
| 2 | Avaliações conceituais | `ConceptualExam` | `ConceptualExamValue` (filtra por discipline_id, só órfãos são removidos) |
| 3 | Recuperações | `RecoveryDiaryRecord` | `RecoveryDiaryRecordStudent`, `SchoolTermRecoveryDiaryRecord`, `FinalRecoveryDiaryRecord`, `AvaliationRecoveryDiaryRecord`, `AvaliationRecoveryLowestNote` |
| 4 | Frequências diárias | `DailyFrequency` | `DailyFrequencyStudent` (destruído explicitamente antes do pai) |
| 5 | Registros de conteúdo | `DisciplineContentRecord` | `ContentRecord`, `ContentRecordsContent` (via `dependent: :destroy`) |
| 6 | Planos de aula | `DisciplineLessonPlan` | `LessonPlan`, `ContentsLessonPlan`, `ObjectivesLessonPlan`, `LessonPlanAttachment` (via `dependent: :destroy`) |
| 7 | Planos de ensino | `DisciplineTeachingPlan` | `TeachingPlan`, `ContentsTeachingPlan`, `ObjectivesTeachingPlan`, `TeachingPlanAttachment` (via `dependent: :destroy`) |
| 8 | Diário de observações | `ObservationDiaryRecord` | `ObservationDiaryRecordNote`, `ObservationDiaryRecordNoteStudent`, `ObservationDiaryRecordAttachment` |
| 9 | Exames complementares | `ComplementaryExam` | `ComplementaryExamStudent` |
| 10 | Avaliações descritivas | `DescriptiveExam` | `DescriptiveExamStudent` |
| 11 | Notas de transferência | `TransferNote` | `DailyNoteStudent` (snapshot antes do `before_destroy` que nullifica `transfer_note_id` e `note`) |

---

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `app/controllers/api/v2/discipline_records_controller.rb` | Controller com endpoints `count` e `destroy_batch` |
| `app/services/api/discipline_records_query.rb` | Resolve api_codes em IDs internos e monta scopes |
| `app/services/api/discipline_records_counter.rb` | Conta registros por tipo usando os scopes da query |
| `app/services/api/discipline_records_destroyer.rb` | Exclui registros em ordem de FK com snapshot JSON |
| `app/models/discipline_record_deletion.rb` | Model de rastreabilidade (1 por execução) |
| `app/models/discipline_record_deletion_posting.rb` | Snapshot JSON por record type |
| `app/enumerations/discipline_record_deletion_status.rb` | Enumeração de status (processing, completed, error) |
| `app/workers/discipline_records_destroyer_worker.rb` | Worker Sidekiq que processa a exclusão e envia callback |
| `db/migrate/20260306171550_create_discipline_record_deletions.rb` | Migration das tabelas de rastreabilidade |
| `lib/tasks/cleanup_old_discipline_record_deletions.rake` | Rake task de limpeza de dados antigos |
| `config/routes.rb` | Rotas: `POST /api/v2/discipline_records/count` e `destroy_batch` |

---

## Considerações Técnicas

- **Processamento assíncrono:** O `destroy_batch` enfileira um worker Sidekiq e retorna `{ queued: true }` imediatamente. O resultado é enviado via callback HTTP.
- **Callback:** Ao finalizar, o worker faz POST na `callback_url` com header `token` (api_security_token) e payload JSON com `success`, `deleted` ou `error`.
- **Transação:** Toda a exclusão ocorre dentro de uma transação. Se qualquer `destroy!` falhar, nenhum registro é excluído.
- **Idempotência:** Chamar `destroy_batch` duas vezes com os mesmos filtros é seguro — o segundo callback retorna `deleted: 0` (mas cria um novo `discipline_record_deletion` com `total_deleted: 0`).
- **Status:** Cada `DisciplineRecordDeletion` tem status `processing` → `completed` ou `error`, controlado pela enumeração `DisciplineRecordDeletionStatus`.
- **Audit trail:** Cada registro excluído gera um audit com `username: "discipline_record_deletion_id:N:ieducar_user:M"`.
- **Snapshot JSON:** Os atributos completos são salvos em `records_data` (jsonb) na tabela `discipline_record_deletion_postings`, independente da tabela `audits`. Isso resolve o problema de models com `audited except:` que excluem FKs críticas.
- **HABTM:** A join table `avaliations_grades` não tem model ActiveRecord. O snapshot é capturado via `SELECT *` direto e restaurado via INSERT SQL.
- **TransferNote:** O callback `before_destroy` nullifica `transfer_note_id` e `note` nos `DailyNoteStudent` vinculados (não os exclui). O snapshot é capturado **antes** do `destroy!` com record type `TransferNoteDailyNoteStudent`.
- **Calendário escolar:** As queries usam a data real de início do calendário da turma (`SchoolCalendarClassroom` ou `SchoolCalendar`), não 1º de janeiro.
- **Discardable:** Models com soft-delete são consultados com `with_discarded` tanto na exclusão quanto no snapshot para evitar registros órfãos.
- **DailyFrequencyStudent:** Destruído explicitamente **antes** do `DailyFrequency` para evitar dupla contagem no callback `before_destroy`.
- **Limpeza:** Dados de rastreabilidade são removidos automaticamente via rake task mensal (ano anterior + mínimo 1 mês de criação).
