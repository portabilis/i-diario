class ConceptualExamValueCreator
  def self.create_empty_by(classroom_id, teacher_id, grade_id, discipline_id)
    new(classroom_id, teacher_id, grade_id, discipline_id).create_empty
  end

  def initialize(classroom_id, teacher_id, grade_id, discipline_id)
    raise ArgumentError if classroom_id.blank? || teacher_id.blank? || grade_id.blank? || discipline_id.blank?

    @classroom_id = classroom_id
    @teacher_id = teacher_id
    @discipline_id = discipline_id
    @grade_id = grade_id
  end

  def create_empty
    return if Discipline.find_by(id: discipline_id).grouper?
    return unless disciplines_in_grade

    conceptual_exam_values_to_create.each do |record|
      student_enrollment_id = student_enrollment_id(record.student_id, classroom_id, record.recorded_at)

      next if student_enrollment_id.blank?
      next if exempted_discipline?(student_enrollment_id, record.discipline_id, record.step_number)

      begin
        ConceptualExamValue.create_with(
          value: nil,
          exempted_discipline: false
        ).find_or_create_by!(
          conceptual_exam_id: record.conceptual_exam_id,
          discipline_id: record.discipline_id
        )
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end

  private

  attr_accessor :teacher_id, :classroom_id, :grade_id, :discipline_id

  def conceptual_exam_values_to_create
    steps = @school_calendar_discipline_grade.steps
    steps_number = if steps.blank?
                    nil
                   else
                    JSON.parse(steps)
                   end

    query = query_teacher_discipline_classrooms

    query = if steps_number
              query.where(conceptual_exams: { classroom_id: classroom_id, step_number: steps_number })
            else
              query.where(conceptual_exams: { classroom_id: classroom_id })
            end

    query.select(
      <<-SQL
        conceptual_exams.id AS conceptual_exam_id,
        conceptual_exams.student_id AS student_id,
        conceptual_exams.recorded_at AS recorded_at,
        conceptual_exams.step_number AS step_number,
        teacher_discipline_classrooms.discipline_id AS discipline_id
      SQL
    )
  end

  def query_teacher_discipline_classrooms
    TeacherDisciplineClassroom.joins(classroom: :conceptual_exams)
                              .joins(join_conceptual_exam_value)
                              .by_teacher_id(teacher_id)
                              .by_classroom(classroom_id)
                              .by_discipline_id(discipline_id)
                              .by_grade_id(grade_id)
                              .where(conceptual_exam_values: { id: nil })
  end

  def join_conceptual_exam_value
    <<-SQL
      LEFT JOIN conceptual_exam_values
             ON conceptual_exam_values.conceptual_exam_id = conceptual_exams.id
            AND conceptual_exam_values.discipline_id = teacher_discipline_classrooms.discipline_id
    SQL
  end

  def student_enrollment_id(student_id, classroom_id, recorded_at)
    StudentEnrollment.by_student(student_id)
                     .by_classroom(classroom_id)
                     .by_grade(grade_id)
                     .by_date(recorded_at)
                     .first
                     .try(:id)
  end

  def exempted_discipline?(student_enrollment_id, discipline_id, step_number)
    StudentEnrollmentExemptedDiscipline.by_student_enrollment(student_enrollment_id)
                                       .by_discipline(discipline_id)
                                       .by_step_number(step_number)
                                       .exists?
  end

  def disciplines_in_grade
    classroom = Classroom.joins(:unity).find_by(id: classroom_id)
    school_calendar = classroom.unity.school_calendars.find_by(year: classroom.year)

    @school_calendar_discipline_grade ||= SchoolCalendarDisciplineGrade.find_by(
      school_calendar: school_calendar, grade_id: grade_id, discipline_id: discipline_id
    )
  end
end
