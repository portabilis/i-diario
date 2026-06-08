# frozen_string_literal: true

class ConceptualExamsFetcher
  def initialize(user:, teacher_id:, unity:, classrooms:, disciplines:)
    @user = user
    @teacher_id = teacher_id
    @unity = unity
    @classrooms = classrooms
    @disciplines = disciplines
  end

  def self.fetch!(**args)
    new(**args).fetch!
  end

  def fetch!
    if @user.current_role_is_admin_or_employee?
      for_admin
    else
      for_teacher
    end
  end

  private

  # Admin/funcionário enxerga TODAS as avaliações conceituais das turmas com
  # vínculo conceitual, sem restringir por professor — enxerga a turma inteira.
  def for_admin
    ConceptualExam.includes(:student, :classroom)
                  .by_unity(@unity)
                  .where(classroom_id: conceptual_classroom_ids)
                  .ordered_by_date_and_student
  end

  def for_teacher
    ConceptualExam.includes(:student, :classroom)
                  .by_unity(@unity)
                  .by_classroom(classroom_ids)
                  .by_teacher(@teacher_id)
                  .ordered_by_date_and_student
  end

  def conceptual_classroom_ids
    TeacherDisciplineClassroom
      .by_teacher_id(@teacher_id)
      .by_classroom(classroom_ids)
      .by_discipline_id(discipline_ids)
      .where(score_type: [ScoreTypes::CONCEPT, nil])
      .pluck(:classroom_id)
  end

  def classroom_ids
    @classrooms.map(&:id)
  end

  def discipline_ids
    @disciplines.map(&:id)
  end
end
