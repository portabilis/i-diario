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
    MigrationObjective.where("description ILIKE ' %'").each do |objective|
      next if objective.description.present?

      MigrationObjectivesTeachingPlan.where(objective_id: objective.id).each(&:destroy)
      MigrationObjectivesLessonPlan.where(objective_id: objective.id).each(&:destroy)

      objective.destroy
    end
  end
end
