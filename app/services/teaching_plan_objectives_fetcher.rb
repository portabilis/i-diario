class TeachingPlanObjectivesFetcher
  YEARLY_SCHOOL_TERM_TYPE_STEP_ID = nil

  def fetch
    teaching_plans.map(&:objectives).uniq.flatten
  end

  protected

  def base_query; end

  def teaching_plans
    @teaching_plans ||= begin
      teaching_plans = base_query

      teacher_teaching_plans = teaching_plans.by_teacher_id(@teacher.id)
      return teacher_teaching_plans if teacher_teaching_plans.exists?

      other_teaching_plans = teaching_plans.by_other_teacher_id(@teacher.id)
      return other_teaching_plans if other_teaching_plans.exists?

      general_teaching_plans = teaching_plans.by_secretary
      general_teaching_plans || []
    end
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(@classroom)
  end

  def school_calendar_year
    steps_fetcher.school_calendar.try(:year) || @start_date.to_date.year
  end

  def school_term_type_steps_ids
    return [] unless (step = steps_fetcher.step_by_date(@start_date.to_date))

    steps_number = step.school_calendar_parent.steps.size
    steps_numbers = steps_fetcher.steps_by_date_range(@start_date.to_date, @end_date.to_date).map(&:step_number)

    school_term_type_steps_ids = SchoolTermTypeStep.joins(:school_term_type)
                                                   .where(school_term_types: { steps_number: steps_number })
                                                   .where(step_number: steps_numbers)
                                                   .pluck(:id)
    school_term_type_steps_ids << YEARLY_SCHOOL_TERM_TYPE_STEP_ID
  end
end
