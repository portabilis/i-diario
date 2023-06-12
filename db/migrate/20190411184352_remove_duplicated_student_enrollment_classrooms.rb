class RemoveDuplicatedStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    ids = StudentEnrollmentClassroom.select('MAX(id) as id')
                                    .group(
                                      :student_enrollment_id,
                                      :classroom_id,
                                      :joined_at
                                    )
                                    .collect(&:id)

    StudentEnrollmentClassroom.where.not(id: ids).delete_all
  end
end
