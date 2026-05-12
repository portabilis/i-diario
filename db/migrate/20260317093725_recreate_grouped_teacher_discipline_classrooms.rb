class RecreateGroupedTeacherDisciplineClassrooms < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP VIEW IF EXISTS grouped_teacher_discipline_classrooms;
    SQL

    create_view :grouped_teacher_discipline_classrooms, version: 2
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS grouped_teacher_discipline_classrooms;
    SQL

    create_view :grouped_teacher_discipline_classrooms, version: 1
  end
end
