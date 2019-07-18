class ConceptualExamValueCreator
  def self.create_empty_by(classroom_id, teacher_id)
    new(classroom_id, teacher_id).create_empty_conceptual_exam_value
  end

  def initialize(classroom_id, teacher_id)
    raise ArgumentError if classroom_id.blank? || teacher_id.blank?

    @classroom = Classroom.find(classroom_id)
    @teacher_id = teacher_id
  end

  def create_empty_conceptual_exam_value
    ConceptualExam.where(classroom_id: @classroom.id).each do |conceptual_exam|
      TeacherDisciplineClassroom.by_teacher_id(@teacher_id)
                                .by_classroom(@classroom)
                                .joins(join_conceptual_exam_value(conceptual_exam.id))
                                .where('conceptual_exam_values.id IS NULL').each do |teacher_discipline_classroom|
        ConceptualExamValue.create!(
          conceptual_exam_id: conceptual_exam.id,
          discipline_id: teacher_discipline_classroom.discipline_id,
          value: nil,
          exempted_discipline: false
        )
      end
    end
  end

  def join_conceptual_exam_value(conceptual_exam_id)
    <<-SQL
      LEFT JOIN conceptual_exam_values
             ON conceptual_exam_values.discipline_id = teacher_discipline_classrooms.discipline_id
            AND conceptual_exam_values.conceptual_exam_id = #{conceptual_exam_id}
    SQL
  end
end
