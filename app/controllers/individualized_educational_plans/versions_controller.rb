module IndividualizedEducationalPlans
  class VersionsController < ApplicationController
    before_action :require_current_teacher
    before_action :require_current_classroom

    def index
      @individualized_educational_plan = IndividualizedEducationalPlan.find(
        params[:individualized_educational_plan_id]
      )
      @versions = @individualized_educational_plan.iep_versions.includes(:published_by).recent_first

      authorize @individualized_educational_plan, :show?
    end
  end
end
