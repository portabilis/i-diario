# Serializa o PEI completo em um hash por seção, com NOMES já resolvidos (aluno,
# turma, componentes, opções...). É a estrutura canônica usada:
#   - pelo publisher, para congelar a versão publicada (jsonb imutável);
#   - pela visualização/PDF, para renderizar tanto o plano vivo quanto uma versão
#     (mesma estrutura => mesma renderização).
#
# Junto de cada nome/descrição vai o ID REAL do registro que o originou, como metadado para
# eventual restauração operacional. Nada os lê de volta — o Restorer reconstrói a versão com ids
# sintéticos e o PDF renderiza por lista fixa de campos —, então são sempre chaves ADITIVAS:
# versão publicada antes deles continua renderizando igual.
#
# O id não substitui o nome congelado: resolver disciplina/opção por id na leitura faria a versão
# exibir o nome ATUAL do registro, quebrando a imutabilidade que é o motivo de existir o snapshot.
class IndividualizedEducationalPlanSnapshot
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
      'curricular_plannings' => section_lines(curricular_plannings) { |line|
        line.slice('long_term_goal', 'stage_objectives', 'skills_to_develop', 'methodologies')
            .merge(accommodations(line))
      },
      'periodic_evaluations' => section_lines(periodic_evaluations) { |line|
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
    regent = @classroom&.regent

    {
      'plan_id' => plan.id,
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
    plan.slice('family_guidelines', 'external_professionals_guidelines').merge(
      'accompaniment' => selected_option_descriptions(:accompaniment),
      'accompaniment_option_ids' => selected_option_ids(:accompaniment),
      'support_type' => selected_option_descriptions(:support_type),
      'support_type_option_ids' => selected_option_ids(:support_type)
    )
  end

  # Linhas das seções 4/5 com a revisão e o componente resolvidos por nome, cada um precedido
  # pelo id do registro de origem.
  def section_lines(lines)
    lines.map do |line|
      {
        'id' => line.id,
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
