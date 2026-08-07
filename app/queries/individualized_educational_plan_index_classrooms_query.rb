# Turma(s) por aluno para o index do PEI: como o PEI não guarda turma, ela é derivada da matrícula
# (turmas que o aluno cursa hoje) e da autoria das versões. Recebe os planos da página e os ids das
# turmas acessíveis do usuário.
class IndividualizedEducationalPlanIndexClassroomsQuery
  # Turmas exibidas na linha do aluno: as que ele cursa hoje + as que publicaram versão
  # (contribuíram). Uma turma que contribuiu permanece na lista mesmo após a transferência.
  Entry = Struct.new(:classrooms) do
    def unities_label
      classrooms.map(&:unity).uniq.join(', ')
    end

    def classrooms_label
      classrooms.join(', ')
    end
  end

  def initialize(plans, accessible_classroom_ids)
    @plans = plans
    @classroom_ids = accessible_classroom_ids
  end

  # student_id => Entry com TODAS as turmas acessíveis ligadas ao PEI: cursando hoje ∪ turmas
  # autoras. Ex.: aluno em regular + AEE aparece nas duas; se saiu da AEE mas ela publicou versão,
  # a AEE permanece. Fica de fora só quando o aluno não cursa nem tem autoria em turma acessível.
  def display_classrooms
    return {} if student_ids.empty?

    ids_by_student = union(attending_ids_by_student, authoring_ids_by_student)
    classrooms = Classroom.where(id: ids_by_student.values.flatten.uniq).includes(:unity).index_by(&:id)

    ids_by_student.each_with_object({}) do |(sid, ids), acc|
      list = ids.map { |id| classrooms[id] }.compact.sort_by(&:to_s)
      acc[sid] = Entry.new(list) unless list.empty?
    end
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

  # student_id => ids das turmas acessíveis que o aluno CURSA hoje.
  def attending_ids_by_student
    StudentEnrollmentClassroom
      .by_classroom(classroom_ids)
      .attending_on(Date.current)
      .by_student(student_ids)
      .joins(classrooms_grade: :classroom)
      .pluck('student_enrollments.student_id', 'classrooms.id')
      .each_with_object({}) { |(sid, cid), acc| (acc[sid] ||= []) << cid }
  end

  # student_id => ids das turmas acessíveis que PUBLICARAM versão do PEI do aluno (autoria). Traz
  # todas as turmas autoras (não só a mais recente): se A e B publicaram, ambas entram na coluna.
  def authoring_ids_by_student
    student_id_by_plan = plans.each_with_object({}) { |plan, acc| acc[plan.id] = plan.student_id }

    IepVersion
      .where(individualized_educational_plan_id: student_id_by_plan.keys)
      .by_classroom(classroom_ids)
      .pluck(:individualized_educational_plan_id, :classroom_id)
      .each_with_object({}) { |(pid, cid), acc| (acc[student_id_by_plan[pid]] ||= []) << cid }
  end

  # Une os dois mapas por student_id, sem repetir turma.
  def union(attending, authoring)
    (attending.keys | authoring.keys).each_with_object({}) do |sid, acc|
      acc[sid] = attending.fetch(sid, []) | authoring.fetch(sid, [])
    end
  end
end
