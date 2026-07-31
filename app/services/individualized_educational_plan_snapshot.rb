# Serializa o PEI completo em um hash por seção, com NOMES já resolvidos (aluno,
# turma, componentes, opções...). É a estrutura canônica usada:
#   - pelo publisher, para congelar a versão publicada (jsonb imutável);
#   - pela visualização/PDF, para renderizar tanto o plano vivo quanto uma versão
#     (mesma estrutura => mesma renderização).
class IndividualizedEducationalPlanSnapshot
  def initialize(plan, student_data: nil)
    @plan = plan
    @student_data = student_data
  end

  def self.build(plan, student_data: nil)
    new(plan, student_data: student_data).build
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
           IndividualizedEducationalPlanPrefill.student_data(plan.student, classroom: plan.classroom)

    {
      'student_name' => plan.student.name,
      'birth_date' => data[:birth_date],
      'guardians' => data[:guardians],
      'guardians_unavailable' => data[:guardians_unavailable],
      'diagnosis' => data[:diagnosis],
      'shift' => data[:shift],
      'unity_name' => plan.unity.name,
      'classroom_name' => plan.classroom.description,
      'teacher_name' => plan.teacher&.name,
      'aee_teacher_name' => plan.aee_teacher&.name,
      'support_professional' => plan.support_professional,
      'year' => plan.year,
      'elaborated_at' => plan.elaborated_at,
      'review_dates' => ordered_review_dates.map(&:review_date)
    }
  end

  def characterization
    plan.slice('characterization', 'clinical_diagnosis_justification', 'school_history',
               'potentialities', 'difficulties', 'preferences_interests', 'effective_strategies')
        .merge(
          'communication_profile' => selected_option_descriptions(:communication_profile),
          'social_interaction_profile' => selected_option_descriptions(:social_interaction_profile),
          'autonomy' => selected_option_descriptions(:autonomy)
        )
  end

  def support_team
    plan.slice('family_guidelines', 'external_professionals_guidelines').merge(
      'accompaniment' => selected_option_descriptions(:accompaniment),
      'support_type' => selected_option_descriptions(:support_type)
    )
  end

  # Linhas das seções 4/5 com a revisão e o componente resolvidos por nome.
  def section_lines(lines)
    lines.map do |line|
      {
        'review_number' => review_number(line.iep_review_date_id),
        'review_date' => line.iep_review_date.review_date,
        'component_type' => line.discipline_id.present? ? 'discipline' : 'knowledge_area',
        'component_name' => line.discipline&.description || line.knowledge_area&.description
      }.merge(yield(line))
    end
  end

  def accommodations(line)
    options = line.iep_curricular_planning_options.map(&:iep_option)

    {
      'instructional_accommodations' => option_descriptions(options, :instructional_accommodation),
      'environmental_accommodations' => option_descriptions(options, :environmental_accommodation),
      'assessment_accommodations' => option_descriptions(options, :assessment_accommodation)
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

  def selected_options
    @selected_options ||= plan.iep_selected_options.includes(:iep_option).map(&:iep_option)
  end

  def option_descriptions(options, kind)
    kind_value = IepOptionKinds.value_of(kind)
    options.select { |option| option.kind == kind_value }.map(&:description)
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
