# Reconstrói um PEI em memória a partir do snapshot de uma versão publicada, para
# renderizar a MESMA tela de formulário em modo leitura (view_only).
#
# Os nomes vêm CONGELADOS do snapshot: os stand-ins (aluno, opções, disciplinas...) são
# instâncias NÃO salvas das classes reais, com ids sintéticos apenas para amarrar as
# associações em memória. Nada é reconsultado no banco — se a opção/disciplina foi
# renomeada ou removida depois, a versão continua mostrando o valor da época (imutável).
#
# Retorna o plano + as coleções que o formulário usa para os selects (já com os mesmos
# stand-ins, para os rótulos resolverem) + os anexos congelados (filename/url do snapshot).
class IndividualizedEducationalPlanSnapshotRestorer
  # Snapshot inválido/corrompido (mínimo ausente ou revisão não resolvida): a tela de versão
  # trata e avisa, em vez de renderizar um documento imutável em branco/incompleto.
  class InvalidSnapshot < StandardError; end

  Result = Struct.new(:plan, :students, :aee_teachers, :iep_options_by_kind, :attachments)

  def self.restore(content)
    new(content).restore
  end

  def initialize(content)
    @content = (content || {}).to_h
    @sequence = 0
    @options_by_kind = Hash.new { |hash, kind| hash[kind] = [] }
    @review_id_by_number = {}
  end

  def restore
    raise InvalidSnapshot, 'snapshot sem student_name na identificação' if identification['student_name'].blank?

    plan = build_plan
    build_review_dates(plan)
    build_curricular_plannings(plan)
    build_periodic_evaluations(plan)

    plan.readonly!

    Result.new(plan, [plan.student].compact, [plan.aee_teacher].compact,
               @options_by_kind, Array(identification['attachments']))
  end

  private

  attr_reader :content

  def identification
    content['identification'] || {}
  end

  def characterization
    content['characterization'] || {}
  end

  def support_team
    content['support_team'] || {}
  end

  def final_evaluation
    content['final_evaluation'] || {}
  end

  # Id sintético NEGATIVO: se vazar para um hidden de FK, nunca casa com um PK real (positivo).
  def next_id
    @sequence -= 1
  end

  def build_plan
    plan = IndividualizedEducationalPlan.new(
      year: identification['year'],
      elaborated_at: parse_date(identification['elaborated_at']),
      support_professional: identification['support_professional'],
      characterization: characterization['characterization'],
      clinical_diagnosis_justification: characterization['clinical_diagnosis_justification'],
      school_history: characterization['school_history'],
      potentialities: characterization['potentialities'],
      difficulties: characterization['difficulties'],
      preferences_interests: characterization['preferences_interests'],
      effective_strategies: characterization['effective_strategies'],
      family_guidelines: support_team['family_guidelines'],
      external_professionals_guidelines: support_team['external_professionals_guidelines'],
      annual_report: final_evaluation['annual_report'],
      overall_evolution: final_evaluation['overall_evolution'],
      next_year_recommendations: final_evaluation['next_year_recommendations'],
      referrals_made: final_evaluation['referrals_made']
    )

    # Campos só de exibição (não persistidos) — congelados do snapshot.
    plan.unity_name = identification['unity_name']
    plan.classroom_name = identification['classroom_name']
    plan.teacher_name = identification['teacher_name']
    plan.birth_date = identification['birth_date']
    plan.guardians = identification['guardians']
    plan.guardians_unavailable = identification['guardians_unavailable']
    plan.diagnosis = identification['diagnosis']
    plan.shift = identification['shift']

    plan.student = build_named(Student, identification['student_name'], :name)
    plan.aee_teacher = build_named(Teacher, identification['aee_teacher_name'], :name)

    assign_selected_options(plan, characterization, %i[communication_profile social_interaction_profile autonomy])
    assign_selected_options(plan, support_team, %i[accompaniment support_type])

    plan
  end

  # Stand-in não salvo com id sintético (readonly!); nil se sem nome.
  def build_named(klass, name, attribute)
    return if name.blank?

    klass.new(id: next_id, attribute => name).tap(&:readonly!)
  end

  # Cria a opção congelada (readonly) e a registra na coleção do formulário (para o select resolver o rótulo).
  def frozen_option(kind, description)
    option = IepOption.new(id: next_id, kind: IepOptionKinds.value_of(kind), description: description)
    option.readonly!
    @options_by_kind[option.kind] << option
    option
  end

  def assign_selected_options(plan, section, kinds)
    kinds.each do |kind|
      Array(section[kind.to_s]).each do |description|
        option = frozen_option(kind, description)
        plan.iep_selected_options.build(iep_option: option, iep_option_id: option.id)
      end
    end
  end

  def build_review_dates(plan)
    Array(identification['review_dates']).each_with_index do |date, index|
      review = plan.iep_review_dates.build(review_date: parse_date(date))
      review.id = next_id
      review.readonly!
      @review_id_by_number[index + 1] = review.id
    end
  end

  def build_curricular_plannings(plan)
    Array(content['curricular_plannings']).each do |line|
      planning = plan.iep_curricular_plannings.build(
        long_term_goal: line['long_term_goal'],
        stage_objectives: line['stage_objectives'],
        skills_to_develop: line['skills_to_develop'],
        methodologies: line['methodologies']
      )
      planning.id = next_id
      assign_component(planning, line)

      %i[instructional_accommodation environmental_accommodation assessment_accommodation].each do |kind|
        Array(line["#{kind}s"]).each do |description|
          option = frozen_option(kind, description)
          planning.iep_curricular_planning_options.build(iep_option: option, iep_option_id: option.id)
        end
      end

      planning.readonly!
    end
  end

  def build_periodic_evaluations(plan)
    Array(content['periodic_evaluations']).each do |line|
      evaluation = plan.iep_periodic_evaluations.build(
        acquired_skills: line['acquired_skills'],
        in_progress_skills: line['in_progress_skills'],
        not_acquired_skills: line['not_acquired_skills'],
        period_report: line['period_report'],
        next_stage_adjustments: line['next_stage_adjustments']
      )
      evaluation.id = next_id
      assign_component(evaluation, line)
      evaluation.readonly!
    end
  end

  # Amarra a linha à revisão (pelo número congelado) e ao componente (disciplina/campo).
  def assign_component(line, snapshot_line)
    review_number = snapshot_line['review_number']
    review_id = @review_id_by_number[review_number.to_i]

    # Revisão não resolvida: a linha sumiria da tela sem aviso — falha alto (a escrita já é rígida).
    if review_id.nil?
      raise InvalidSnapshot, "linha de componente com revisão não resolvida (review_number=#{review_number.inspect})"
    end

    line.iep_review_date_id = review_id

    if snapshot_line['component_type'] == 'discipline'
      line.discipline = build_named(Discipline, snapshot_line['component_name'], :description)
    else
      line.knowledge_area = build_named(KnowledgeArea, snapshot_line['component_name'], :description)
    end
  end

  # Datas do snapshot vêm como string ISO; o plano vivo usa Date. Erro esperado mantém o valor.
  def parse_date(value)
    return value if value.blank? || value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue ArgumentError
    value
  end
end
