class KnowledgeAreaLessonPlanReportController < ApplicationController

  def form
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(unity_id: current_user_unity.id)
    fetch_collections
  end

  def report
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(resource_params)

    if @knowledge_area_lesson_plan_report_form.valid?
      knowledge_area_lesson_plan_report = KnowledgeAreaLessonPlanReport.build(current_entity_configuration,
                                                              @knowledge_area_lesson_plan_report_form.date_start,
                                                              @knowledge_area_lesson_plan_report_form.date_end,
                                                              @knowledge_area_lesson_plan_report_form.knowledge_area_lesson_plan,
                                                              current_teacher)

      send_data(knowledge_area_lesson_plan_report.render, filename: 'registo-de-conteudo-por-areas-de-conhecimento.pdf', type: 'application/pdf', disposition: 'inline')
    else
      @knowledge_area_lesson_plan_report_form
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @knowledge_areas = KnowledgeArea.all
  end

  def resource_params
    params.require(:knowledge_area_lesson_plan_report_form).permit(:unity_id,
                                                          :teacher_id,
                                                          :classroom_id,
                                                          :date_start,
                                                          :date_end,
                                                          :knowledge_area_id)
  end
end
