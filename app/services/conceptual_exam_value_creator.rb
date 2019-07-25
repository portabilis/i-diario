class ConceptualExamValueCreator
  def self.create_empty_by(classroom_id, teacher_id)
    new(classroom_id, teacher_id).create_empty
  end

  def initialize(classroom_id, teacher_id)
    raise ArgumentError if classroom_id.blank? || teacher_id.blank?

    @classroom = Classroom.find(classroom_id)
    @teacher_id = teacher_id
  end

  def create_empty
    TeacherDisciplineClassroom.joins(join_conceptual_exam_value)
                              .joins(join_conceptual_exam)
                              .select(
                                'conceptual_exams.id AS conceptual_exam_id,
                                teacher_discipline_classrooms.discipline_id AS discipline_id'
                              )
                              .by_teacher_id(@teacher_id)
                              .by_classroom(@classroom)
                              .where('conceptual_exams.discarded_at IS NULL')
                              .where('conceptual_exam_values.id IS NULL').each do |record|
      ConceptualExamValue.create!(
        conceptual_exam_id: record.conceptual_exam_id,
        discipline_id: record.discipline_id,
        value: nil,
        exempted_discipline: false
      )
    end
  end

  def join_conceptual_exam
    <<-SQL
    LEFT JOIN conceptual_exams
           ON conceptual_exams.classroom_id = teacher_discipline_classrooms.classroom_id
    SQL
  end

  def join_conceptual_exam_value
    <<-SQL
      LEFT JOIN conceptual_exam_values
             ON conceptual_exam_values.discipline_id = teacher_discipline_classrooms.discipline_id
    SQL
  end
end
