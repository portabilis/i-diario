class BaseStudentDependenciesDiscarderWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, student_id)
    Entity.find(entity_id).using_connection do
      yield
    end
  end

  protected

  def joins_step_by_step_number_and_classroom(classroom_id_column, step_number_column)
    <<-SQL
      ,step_by_classroom(
        #{classroom_id_column}, #{step_number_column}
      ) AS step
    SQL
  end

  def exists_enrollment_by_date_column(classroom_id_column, start_date_column, end_date_column = nil)
    end_date_column = start_date_column if end_date_column.blank?

    <<-SQL
      EXISTS(
        SELECT 1
          FROM student_enrollments
          JOIN student_enrollment_classrooms
            ON student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
           AND student_enrollment_classrooms.discarded_at IS NULL
          JOIN classrooms_grades
            ON classrooms_grades.id = student_enrollment_classrooms.classrooms_grade_id
         WHERE student_enrollments.student_id = :student_id
           AND student_enrollments.discarded_at IS NULL
           AND student_enrollments.active = 1
           AND classrooms_grades.classroom_id = #{classroom_id_column}
           AND #{start_date_column} >= CAST(student_enrollment_classrooms.joined_at AS DATE) AND
               (
                 COALESCE(student_enrollment_classrooms.left_at, '') = '' OR
                 (
                   #{end_date_column} <= CAST(student_enrollment_classrooms.left_at AS DATE) AND
                   student_enrollment_classrooms.joined_at <> student_enrollment_classrooms.left_at
                 )
               )
      )
    SQL
  end

  def not_exists_enrollment_by_date_column(classroom_id_column, start_date_column, end_date_column = nil)
    'NOT ' << exists_enrollment_by_date_column(classroom_id_column, start_date_column, end_date_column)
  end
end
