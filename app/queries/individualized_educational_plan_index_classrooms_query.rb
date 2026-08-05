# Dados de turma por aluno para o index do PEI, derivados do grafo de matrícula (o plano não tem
# mais coluna de turma). Recebe os planos da página e os ids das turmas acessíveis do usuário.
class IndividualizedEducationalPlanIndexClassroomsQuery
  def initialize(plans, accessible_classroom_ids)
    @plans = plans
    @classroom_ids = accessible_classroom_ids
  end

  # student_id => turma exibida: prefere a turma acessível onde o aluno está enturmado (aberta
  # primeiro); se o plano é visível só por AUTORIA (aluno não cursa turma acessível), cai na turma
  # que publicou a versão — senão a linha ficaria com escola/turma em branco.
  def display_classrooms
    return {} if student_ids.empty?

    map = enrolled_classrooms_by_student
    fill_authoring_classrooms(map, plans.reject { |plan| map.key?(plan.student_id) })
    map
  end

  # Set de student_ids que o usuário pode editar (cursando turma acessível hoje) — uma query só,
  # para o index decidir por linha se HABILITA o botão "Editar" sem N+1 de plan_editable?.
  def editable_student_ids
    return Set.new if plans.empty?

    StudentEnrollmentClassroom
      .by_classroom(classroom_ids)
      .attending_on(Date.current)
      .by_student(student_ids)
      .joins(:student_enrollment)
      .pluck('student_enrollments.student_id')
      .to_set
  end

  private

  attr_reader :plans, :classroom_ids

  def student_ids
    @student_ids ||= plans.map(&:student_id)
  end

  def enrolled_classrooms_by_student
    rows = StudentEnrollmentClassroom
           .by_classroom(classroom_ids)
           .by_student(student_ids)
           .joins(classrooms_grade: :classroom)
           .order(Arel.sql("CASE WHEN left_at IS NULL OR left_at = '' THEN 0 ELSE 1 END"))
           .pluck('student_enrollments.student_id', 'classrooms.id')
    classrooms = Classroom.where(id: rows.map(&:last).uniq).includes(:unity).index_by(&:id)
    rows.each_with_object({}) { |(sid, cid), map| map[sid] ||= classrooms[cid] }
  end

  # Preenche (em lote, sem N+1) os planos sem enturmação acessível com a turma autora mais recente.
  # Ex.: plano do aluno João publicado pela turma B; João foi transferido → a linha mostra B.
  def fill_authoring_classrooms(map, plans_without_classroom)
    return if plans_without_classroom.empty?

    classroom_by_plan = IepVersion
                        .where(individualized_educational_plan_id: plans_without_classroom.map(&:id))
                        .by_classroom(classroom_ids)
                        .recent_first
                        .pluck(:individualized_educational_plan_id, :classroom_id)
                        .each_with_object({}) { |(pid, cid), acc| acc[pid] ||= cid }
    classrooms = Classroom.where(id: classroom_by_plan.values.uniq).includes(:unity).index_by(&:id)
    plans_without_classroom.each { |plan| map[plan.student_id] ||= classrooms[classroom_by_plan[plan.id]] }
  end
end
