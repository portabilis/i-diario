class AddTeacherIdToLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_reference :lesson_plans, :teacher, foreign_key: true

    execute <<-SQL
      UPDATE lesson_plans
         SET teacher_id = (SELECT teacher_id
                             FROM users
                            WHERE id = (SELECT audits.user_id
                                    FROM audits
                                   WHERE audits.auditable_type = 'LessonPlan'
                                     AND audits.action = 'create'
                                     AND audits.auditable_id = lesson_plans.id));
    SQL


  end
end
