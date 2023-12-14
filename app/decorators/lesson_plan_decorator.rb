class LessonPlanDecorator
  include Decore

  def author(current_teacher)
    PlanAuthorFetcher.new(component, current_teacher).author
  end

  def removed_objectives?
    @remove_lesson_plan_objectives ||= GeneralConfiguration.current.remove_lesson_plan_objectives
  end
end
