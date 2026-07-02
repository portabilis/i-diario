# frozen_string_literal: true

class StudentsExemptFromDiscipline
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollments = params.fetch(:student_enrollments)
    @discipline = params.fetch(:discipline)
    @step = params.fetch(:step)
    @classroom_id = params.fetch(:classroom_id, nil)
  end

  def call
    return {} if @student_enrollments.blank?

    if @discipline.present?
      return student_has_exempt_for_step(
        StudentEnrollmentExemptedDiscipline.by_discipline(@discipline.id)
                                           .by_step_number(@step)
                                           .by_student_enrollment(@student_enrollments)
                                           .includes(student_enrollment: [:student])
      )
    else
      return {} if @classroom_id.blank?

      students_exempt_from_all_disciplines
    end
  rescue NoMethodError => errors
    raise errors
  end

  private

  def student_has_exempt_for_step(student_enrollments_exempt)
    exempts_from_discipline = {}

    student_enrollments_exempt.each do |student_exempted|
      exempts_from_discipline[student_exempted.student_enrollment_id] ||= @step
    end

    exempts_from_discipline
  end

  # Retorna alunos dispensados de TODAS as disciplinas da turma
  # Usado quando: frequência unificada (por dia) ou avaliação descritiva geral (sem disciplina específica)
  # Regra: aluno só aparece dispensado se tiver dispensa em 100% das disciplinas da turma
  def students_exempt_from_all_disciplines
    exempts_from_all_disciplines = {}

    classroom_disciplines = classroom_discipline_ids
    return {} if classroom_disciplines.blank?

    all_exemptions = StudentEnrollmentExemptedDiscipline.by_step_number(@step)
                                                        .by_student_enrollment(@student_enrollments)
                                                        .where(discipline_id: classroom_disciplines)
                                                        .pluck(:student_enrollment_id, :discipline_id)

    exemptions_by_student = all_exemptions.group_by(&:first)

    @student_enrollments.each do |student_enrollment_id|
      exempted_disciplines = exemptions_by_student[student_enrollment_id]&.map(&:last) || []

      if classroom_disciplines.all? { |disc_id| exempted_disciplines.include?(disc_id) }
        exempts_from_all_disciplines[student_enrollment_id] = @step
      end
    end

    exempts_from_all_disciplines
  end

  def classroom_discipline_ids
    @classroom_discipline_ids ||= TeacherDisciplineClassroom
                                  .where(classroom_id: @classroom_id)
                                  .distinct
                                  .pluck(:discipline_id)
  end
end
