class RecreateGroupedTeacherDisciplineClassroomsV3 < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      DROP VIEW IF EXISTS grouped_teacher_discipline_classrooms;
    SQL

    create_view :grouped_teacher_discipline_classrooms, version: 3
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS grouped_teacher_discipline_classrooms;
    SQL

    create_view :grouped_teacher_discipline_classrooms, version: 2
  end
end
