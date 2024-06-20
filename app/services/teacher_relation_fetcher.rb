class TeacherRelationFetcher
  def initialize(params)
    @teacher_id = params[:teacher_id]
    @discipline_id = params[:discipline_id]
    @classroom = params[:classroom]
    @grade_ids = params[:grades]
    @knowledge_areas = params[:knowledge_areas]
  end

  def exists_classroom_in_relation?
    teacher_discipline_classrooms.by_classroom(@classroom).exists?
  end

  def exists_discipline_in_relation?
    teacher_discipline_classrooms.by_discipline_id(@discipline_id).exists?
  end

  def exists_knowledge_area_in_relation?
    teacher_discipline_classrooms.by_knowledge_area_id(@knowledge_areas).exists?
  end

  def exists_classroom_and_discipline_in_relation?
    teacher_discipline_classrooms.by_classroom(@classroom)
                                 .by_discipline_id(@discipline_id)
                                 .exists?
  end

  def exists_all_grades_in_relation?
    classroom_ids = teacher_discipline_classrooms.by_grade_id(@grade_ids).pluck(:classroom_id)
    found_grade_ids = ClassroomsGrade.where(classroom_id: classroom_ids, grade_id: @grade_ids)
                                     .pluck(:grade_id).uniq

    (@grade_ids & found_grade_ids) == @grade_ids
  end

  def exists_all_knowledge_areas_in_relation?
    (@knowledge_areas - teacher_knowledge_area_ids).blank?
  end

  private

  def teacher_discipline_classrooms
    @teacher_discipline_classrooms ||= TeacherDisciplineClassroom.by_teacher_id(@teacher_id)
  end

  def teacher_knowledge_area_ids
    teacher_discipline_classrooms.joins(:discipline).pluck(:knowledge_area_id).uniq
  end
end
