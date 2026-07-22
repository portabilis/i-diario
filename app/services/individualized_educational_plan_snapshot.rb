# Serializa o PEI completo em um hash por seção, com NOMES já resolvidos (aluno,
# turma, componentes, opções...). É a estrutura canônica usada:
#   - pelo publisher, para congelar a versão publicada (jsonb imutável);
#   - pela visualização/PDF, para renderizar tanto o plano vivo quanto uma versão
#     (mesma estrutura => mesma renderização).
class IndividualizedEducationalPlanSnapshot
  def initialize(plan)
    @plan = plan
  end

  def self.build(plan)
    new(plan).build
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
    student_data = IndividualizedEducationalPlanPrefill.student_data(plan.student, classroom: plan.classroom)

    {
      'student_name' => plan.student.name,
      'birth_date' => student_data[:birth_date],
      'guardians' => student_data[:guardians],
      'diagnosis' => student_data[:diagnosis],
      'shift' => student_data[:shift],
      'unity_name' => plan.unity.name,
      'classroom_name' => plan.classroom.description,
      'teacher_name' => plan.teacher&.name,
      'aee_teacher_name' => plan.aee_teacher&.name,
      'support_professional' => plan.support_professional,
      'year' => plan.year,
      'elaborated_at' => plan.elaborated_at,
      'review_dates' => ordered_review_dates.map(&:review_date),
      'attachments' => plan.iep_attachments.map { |attachment|
        { 'filename' => attachment.filename, 'url' => attachment.attachment.url }
      }
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
    options = plan.iep_selected_options.includes(:iep_option).map(&:iep_option)
    option_descriptions(options, kind)
  end

  def option_descriptions(options, kind)
    kind_value = IepOptionKinds.value_of(kind)
    options.select { |option| option.kind == kind_value }.map(&:description)
  end

  def ordered_review_dates
    plan.iep_review_dates.sort_by(&:review_date)
  end

  # Posição da revisão (1ª, 2ª...) na ordem cronológica das datas previstas.
  def review_number(review_date_id)
    ordered_review_dates.index { |review| review.id == review_date_id }.to_i + 1
  end
end
