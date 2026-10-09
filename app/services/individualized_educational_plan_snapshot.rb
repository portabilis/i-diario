# Serializa o PEI completo em um hash por seção, com NOMES já resolvidos (aluno,
# turma, componentes, opções...). É a estrutura canônica usada:
#   - pelo publisher, para congelar a versão publicada (jsonb imutável);
#   - pela visualização/PDF, para renderizar tanto o plano vivo quanto uma versão
#     (mesma estrutura => mesma renderização).
#
# Cada nome/descrição resolvido de um registro LOCAL vem acompanhado do id desse registro, como
# metadado de restauração (os campos vindos do i-Educar — responsáveis, diagnóstico, turno,
# nascimento — não têm registro local nem id). São sempre chaves ADITIVAS: versão sem elas
# continua renderizando igual, e a coluna guarda jsonb de formatos heterogêneos.
#
# Regras a manter em quem consumir o snapshot:
#
# - NÃO resolver nome por id na leitura: devolveria o nome ATUAL do registro e quebraria a
#   imutabilidade que é o motivo de existir o snapshot. O cuidado é concreto porque as chaves de
#   opção têm o mesmo nome dos setters de IepMultiSelectable — um assign_attributes(section) no
#   Restorer as pegaria e reataria a IepOption viva.
# - `component_type` é o ÚNICO discriminador entre disciplina e área de conhecimento. Em snapshot
#   sem essas chaves, discipline_id é nil por ausência; em linha por área, é nil por ser área —
#   os dois estados são indistinguíveis, e trocar por `if line['discipline_id']` reclassificaria
#   toda linha antiga de disciplina.
# - Os ids são LOCAIS À ENTITY e são pista de restauração, não referência garantida: resolvê-los
#   fora de entity.using_connection acha um registro diferente e válido em outra rede, e o alvo
#   pode ter sido descartado depois. A descrição gravada ao lado é o critério de conferência.
# - `uses_medication` é o único booleano do documento e é TRI-STATE: false ("Não") é resposta e
#   null é "não respondido". Podar o support_team por present?/compact/reject(&:blank?) apagaria
#   um "Não" de uma versão publicada e imutável, sem erro nenhum.
# - Os medicamentos ficam em `support_team['medications']`, na ordem de cadastro. Versão publicada
#   antes da lista tem só `medication_name`, `medication_dosage` e `medication_schedule`: ler
#   sempre por `medications_from`, que converte esse formato numa lista de uma linha.
class IndividualizedEducationalPlanSnapshot
  LEGACY_MEDICATION_KEYS = { 'name' => 'medication_name', 'dosage' => 'medication_dosage',
                             'schedule' => 'medication_schedule' }.freeze

  # Lista de medicamentos ({ 'name', 'dosage', 'schedule' }) de um support_team, nos dois formatos.
  def self.medications_from(support_team)
    support_team = support_team.to_h
    return Array(support_team['medications']) if support_team.key?('medications')

    legacy = LEGACY_MEDICATION_KEYS.each_with_object({}) { |(key, legacy_key), row| row[key] = support_team[legacy_key] }
    legacy.values.any?(&:present?) ? [legacy] : []
  end

  def initialize(plan, student_data: nil, classroom: nil)
    @plan = plan
    @student_data = student_data
    @classroom = classroom
  end

  def self.build(plan, student_data: nil, classroom: nil)
    new(plan, student_data: student_data, classroom: classroom).build
  end

  def build
    {
      'identification' => identification,
      'characterization' => characterization,
      'support_team' => support_team,
      'curricular_plannings' => section_lines(curricular_plannings, 'iep_curricular_planning_id') { |line|
        line.slice('long_term_goal', 'stage_objectives', 'skills_to_develop', 'methodologies')
            .merge(accommodations(line))
      },
      'periodic_evaluations' => section_lines(periodic_evaluations, 'iep_periodic_evaluation_id') { |line|
        line.slice('acquired_skills', 'in_progress_skills', 'not_acquired_skills',
                   'period_report', 'next_stage_adjustments')
      },
      'final_evaluation' => plan.slice('annual_report', 'overall_evolution',
                                       'next_year_recommendations', 'referrals_made')
    }
  end

  private

  attr_reader :plan

  def identification
    data = @student_data ||
           IndividualizedEducationalPlanPrefill.student_data(plan.student, classroom: @classroom)
    # regent_api_code é a identidade durável do regente: Classroom#regent resolve pelo api_code e
    # devolve nil enquanto o professor não veio do i-Educar, deixando id e nome vazios numa turma
    # que tem regente.
    regent = @classroom&.regent

    {
      'student_id' => plan.student_id,
      'student_name' => plan.student.name,
      'birth_date' => data[:birth_date],
      'guardians' => data[:guardians],
      'guardians_unavailable' => data[:guardians_unavailable],
      'diagnosis' => data[:diagnosis],
      'shift' => data[:shift],
      'unity_id' => @classroom&.unity_id,
      'unity_name' => @classroom&.unity&.name,
      'classroom_id' => @classroom&.id,
      'classroom_name' => @classroom&.description,
      'teacher_api_code' => @classroom&.regent_api_code,
      'teacher_id' => regent&.id,
      'teacher_name' => regent&.name,
      'aee_teacher_id' => plan.aee_teacher_id,
      'aee_teacher_name' => plan.aee_teacher&.name,
      'support_professional' => plan.support_professional,
      'year' => plan.year,
      'elaborated_at' => plan.elaborated_at,
      'review_date_ids' => ordered_review_dates.map(&:id),
      'review_dates' => ordered_review_dates.map(&:review_date)
    }
  end

  def characterization
    plan.slice('characterization', 'clinical_diagnosis_justification', 'school_history',
               'potentialities', 'difficulties', 'preferences_interests', 'effective_strategies')
        .merge(
          'communication_profile' => selected_option_descriptions(:communication_profile),
          'communication_profile_option_ids' => selected_option_ids(:communication_profile),
          'social_interaction_profile' => selected_option_descriptions(:social_interaction_profile),
          'social_interaction_profile_option_ids' => selected_option_ids(:social_interaction_profile),
          'autonomy' => selected_option_descriptions(:autonomy),
          'autonomy_option_ids' => selected_option_ids(:autonomy)
        )
  end

  def support_team
    plan.slice('family_guidelines', 'external_professionals_guidelines',
               'uses_medication', 'medication_notes', 'family_environment_characteristics').merge(
      'medications' => medications,
      'accompaniment' => selected_option_descriptions(:accompaniment),
      'accompaniment_option_ids' => selected_option_ids(:accompaniment),
      'support_type' => selected_option_descriptions(:support_type),
      'support_type_option_ids' => selected_option_ids(:support_type)
    )
  end

  # Linha removida no formulário (ainda em memória) não entra: o snapshot reflete o que vai ser salvo.
  # Com "Não" a lista fica vazia: a migração do campo único preservou linhas de planos com "Não",
  # que só são descartadas no próximo salvamento.
  def medications
    return [] if plan.uses_medication == false

    plan.iep_medications.reject(&:marked_for_destruction?).map do |medication|
      { 'iep_medication_id' => medication.id }.merge(medication.slice('name', 'dosage', 'schedule'))
    end
  end

  # Linhas das seções 4/5 com a revisão e o componente resolvidos por nome. id_key nomeia a tabela
  # de origem da linha (as duas seções passam por aqui), para a chave não ficar ambígua no documento.
  def section_lines(lines, id_key)
    lines.map do |line|
      {
        id_key => line.id,
        'iep_review_date_id' => line.iep_review_date_id,
        'review_number' => review_number(line.iep_review_date_id),
        'review_date' => line.iep_review_date.review_date,
        'discipline_id' => line.discipline_id,
        'knowledge_area_id' => line.knowledge_area_id,
        'component_type' => line.discipline_id.present? ? 'discipline' : 'knowledge_area',
        'component_name' => line.discipline&.description || line.knowledge_area&.description
      }.merge(yield(line))
    end
  end

  def accommodations(line)
    options = line.iep_curricular_planning_options.map(&:iep_option)

    {
      'instructional_accommodations' => option_descriptions(options, :instructional_accommodation),
      'instructional_accommodation_option_ids' => option_ids(options, :instructional_accommodation),
      'environmental_accommodations' => option_descriptions(options, :environmental_accommodation),
      'environmental_accommodation_option_ids' => option_ids(options, :environmental_accommodation),
      'assessment_accommodations' => option_descriptions(options, :assessment_accommodation),
      'assessment_accommodation_option_ids' => option_ids(options, :assessment_accommodation)
    }
  end

  def curricular_plannings
    plan.iep_curricular_plannings
        .includes(:discipline, :knowledge_area, :iep_review_date,
                  iep_curricular_planning_options: :iep_option)
  end

  def periodic_evaluations
    plan.iep_periodic_evaluations.includes(:discipline, :knowledge_area, :iep_review_date)
  end

  def selected_option_descriptions(kind)
    option_descriptions(selected_options, kind)
  end

  def selected_option_ids(kind)
    option_ids(selected_options, kind)
  end

  def selected_options
    @selected_options ||= plan.iep_selected_options.includes(:iep_option).map(&:iep_option)
  end

  def option_descriptions(options, kind)
    options_of_kind(options, kind).map(&:description)
  end

  # Id da OPÇÃO (iep_options), não o da linha de junção: a junção é surrogate descartável, recriar
  # a seleção gera outro id. Alinhado por posição com as descrições da mesma categoria.
  def option_ids(options, kind)
    options_of_kind(options, kind).map(&:id)
  end

  # Fonte ÚNICA das descrições e dos ids de uma categoria: as duas arrays são lidas por posição,
  # então precisam sair desta mesma seleção. Filtrar de um lado só desalinharia o par sem que nada
  # reclame — o desalinhamento ficaria congelado no documento e não há leitor para acusá-lo.
  def options_of_kind(options, kind)
    kind_value = IepOptionKinds.value_of(kind)

    options.select { |option| option.kind == kind_value }
  end

  # Query fresca (ordena no SQL) + memoização: a associação em memória pode estar
  # desatualizada — a validação do plano carrega iep_review_dates antes de as datas
  # existirem, e usar esse cache faria o número da revisão sair errado.
  def ordered_review_dates
    @ordered_review_dates ||= plan.iep_review_dates.order(:review_date).to_a
  end

  # Posição da revisão (1ª, 2ª...) na ordem cronológica das datas previstas. Levanta erro se a data
  # não pertencer ao plano (form adulterado/estado obsoleto): no publish! isso vira rollback (em vez
  # de gravar número errado no histórico imutável); no caminho de leitura (ReportPresenter.from_record)
  # sobe como erro, sinalizando o estado inconsistente em vez de mascará-lo com um número inventado.
  def review_number(review_date_id)
    index = ordered_review_dates.index { |review| review.id == review_date_id }
    raise ArgumentError, "iep_review_date_id #{review_date_id} não pertence ao plano #{plan.id}" if index.nil?

    index + 1
  end
end
