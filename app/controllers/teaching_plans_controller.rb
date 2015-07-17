class TeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @teaching_plans = apply_scopes(TeachingPlan.all)

    authorize @teaching_plans
  end
end