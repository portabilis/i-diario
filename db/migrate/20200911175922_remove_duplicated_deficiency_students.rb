class RemoveDuplicatedDeficiencyStudents < ActiveRecord::Migration
  def change
    deficiency_students = DeficiencyStudent.unscoped.group(
      :deficiency_id, :student_id
    ).having(
      'COUNT(1) > 1'
    ).pluck(
      'MAX(id)', :deficiency_id, :student_id
    )

    deficiency_students.each do |correct_id, deficiency_id, student_id|
      DeficiencyStudent.unscoped.where(
        deficiency_id: deficiency_id,
        student_id: student_id
      ).where.not(id: correct_id).each(&:destroy!)
    end
  end
end
