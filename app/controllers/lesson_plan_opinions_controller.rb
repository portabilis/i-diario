class LessonPlanOpinionsController < ApplicationController

  def update
    @lesson_plan = LessonPlan.find_by(id: params[:id])

    authorize @lesson_plan

    if @lesson_plan.update(resource_params)
      render_view_for_plan
    else
      flash[:error] = @lesson_plan.errors.full_messages.to_sentence
      redirect_to new_plan_path
    end
  end

  private

  def resource_params
    if params[:discipline_lesson_plan]
      params.require(:discipline_lesson_plan).require(:lesson_plan_attributes).permit(:opinion, :validated)
    elsif params[:knowledge_area_lesson_plan]
      params.require(:knowledge_area_lesson_plan).require(:lesson_plan_attributes).permit(:opinion, :validated)
    end
  end

  def render_view_for_plan
    if params[:discipline_lesson_plan]
      respond_with @lesson_plan, location: discipline_lesson_plans_path
    elsif params[:knowledge_area_lesson_plan]
      respond_with @lesson_plan, location: knowledge_area_lesson_plans_path
    else
      render json: { error: 'Unknown plan type' }, status: :unprocessable_entity
    end
  end

  def new_plan_path
    if params[:discipline_lesson_plan]
      new_discipline_lesson_plan_path
    elsif params[:knowledge_area_lesson_plan]
      new_knowledge_area_lesson_plan_path
    end
  end
end