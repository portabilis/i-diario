class LessonPlanDecorator
  include Decore

  def author(current_teacher)
    PlanAuthorFetcher.new(component, current_teacher).author
  end

  def removed_objectives?
    general_configuration = GeneralConfiguration.current
    return false if general_configuration.remove_lesson_plan_objectives

    true
  end
end
