module IndividualizedEducationalPlans
  class VersionsController < ApplicationController
    before_action :require_current_teacher
    before_action :require_current_classroom
    # Controller aninhado: título/breadcrumb/menu usam o item do PEI no navigation.yml.
    before_action { @navigation_item = 'individualized_educational_plans' }

    def index
      @individualized_educational_plan = IndividualizedEducationalPlan.find(
        params[:individualized_educational_plan_id]
      )
      @versions = @individualized_educational_plan.iep_versions.includes(:published_by).recent_first

      authorize @individualized_educational_plan, :show?
    end
  end
end
