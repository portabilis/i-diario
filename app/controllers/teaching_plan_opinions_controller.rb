class TeachingPlanOpinionsController < ApplicationController

  def update
    @teaching_plan = TeachingPlan.find_by(id: params[:id])

    authorize @teaching_plan

    if @teaching_plan.update(resource_params)
      render_view_for_plan
    else
      flash[:error] = @teaching_plan.errors.full_messages.to_sentence
      redirect_to new_plan_path
    end
  end

  private

  def resource_params
    if params[:discipline_teaching_plan]
      params.require(:discipline_teaching_plan).require(:teaching_plan_attributes).permit(:opinion, :validated)
    elsif params[:knowledge_area_teaching_plan]
      params.require(:knowledge_area_teaching_plan).require(:teaching_plan_attributes).permit(:opinion, :validated)
    end
  end

  def render_view_for_plan
    if params[:discipline_teaching_plan]
      respond_with @teaching_plan, location: discipline_teaching_plans_path
    elsif params[:knowledge_area_teaching_plan]
      respond_with @teaching_plan, location: knowledge_area_teaching_plans_path
    else
      render json: { error: 'Unknown plan type' }, status: :unprocessable_entity
    end
  end

  def new_plan_path
    if params[:discipline_teaching_plan]
      new_discipline_teaching_plan_path
    elsif params[:knowledge_area_teaching_plan]
      new_knowledge_area_teaching_plan_path
    end
  end
end