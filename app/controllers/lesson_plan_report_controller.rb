class LessonPlanReportController < ApplicationController

  def form
    @lesson_plan_report_form = LessonPlanReportForm.new()
    fetch_collections
  end

  def report
    @lesson_plan_report_form = LessonPlanReportForm.new(resource_params)


    if @lesson_plan_report_form.valid?
      lesson_plan_report = LessonPlanReport.build(current_entity_configuration,
                                                              @lesson_plan_report_form.date_start,
                                                              @lesson_plan_report_form.date_end,
                                                              @lesson_plan_report_form.discipline_lesson_plan)

      send_data(lesson_plan_report.render, filename: 'registro-de-conteudos-por-disciplina.pdf', type: 'application/pdf', disposition: 'inline')
    else
      @lesson_plan_report_form
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id,
                                                        current_user.current_user_role.unity.id,
                                                        @lesson_plan_report_form.classroom_id,
                                                        @lesson_plan_report_form.discipline_id)
    fetcher.fetch!
    @unities = Unity.by_unity(current_user.current_user_role.unity.id)
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @number_of_classes = current_school_calendar.number_of_classes
    @knowledge_areas = KnowledgeArea.all
  end

  def resource_params
    params.require(:lesson_plan_report_form).permit(:unity_id,
                                                          :classroom_id,
                                                          :discipline_id,
                                                          :date_start,
                                                          :date_end,
                                                          :global_absence,
                                                          :knowledge_area_id)
  end
end