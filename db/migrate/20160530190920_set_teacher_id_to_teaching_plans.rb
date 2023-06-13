class SetTeacherIdToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE teaching_plans
         SET teacher_id = (SELECT teacher_id
                             FROM users
                            WHERE id = (SELECT audits.user_id
                                    FROM audits
                                   WHERE audits.auditable_type = 'TeachingPlan'
                                     AND audits.action = 'create'
                                     AND audits.auditable_id = teaching_plans.id
                                   LIMIT 1));
    SQL
  end
end
