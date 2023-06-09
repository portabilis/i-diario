class RenameColumnSpecificAreaToAllowAbsenceByDisciplineOnTeacherDisciplineClassroom < ActiveRecord::Migration[4.2]
  def change
    rename_column :teacher_discipline_classrooms, :specific_area, :allow_absence_by_discipline
  end
end
