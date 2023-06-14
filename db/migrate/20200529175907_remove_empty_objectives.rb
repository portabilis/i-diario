class RemoveEmptyObjectives < ActiveRecord::Migration[4.2]
  class MigrationObjective < ActiveRecord::Base
    self.table_name = :objectives
  end

  class MigrationObjectivesTeachingPlan < ActiveRecord::Base
    self.table_name = :objectives_teaching_plans
  end

  class MigrationObjectivesLessonPlan < ActiveRecord::Base
    self.table_name = :objectives_lesson_plans
  end

  def change
    MigrationObjective.where("TRIM(COALESCE(description, '')) = ''").each do |objective|
      MigrationObjectivesTeachingPlan.where(objective_id: objective.id)
                                     .each do |objective_teaching_plan|
        objective_teaching_plan.without_auditing do
          objective_teaching_plan.destroy
        end
      end

      MigrationObjectivesLessonPlan.where(objective_id: objective.id)
                                   .each do |objective_lesson_plan|
        objective_lesson_plan.without_auditing do
          objective_lesson_plan.destroy
        end
      end

      objective.without_auditing do
        objective.destroy
      end
    end
  end
end
