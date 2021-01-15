class RemoveEmptyObjectives < ActiveRecord::Migration
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
      MigrationObjectivesTeachingPlan.where(objective_id: objective.id).each(&:destroy)
      MigrationObjectivesLessonPlan.where(objective_id: objective.id).each(&:destroy)

      objective.destroy
    end
  end
end
