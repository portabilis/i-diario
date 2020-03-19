class TeachingPlanContentsFetcher
  def fetch
    teaching_plans.map(&:contents).uniq.flatten
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

  def school_terms
    @school_terms ||= steps_fetcher.steps_by_date_range(@start_date.to_date, @end_date.to_date).map { |step|
      school_term = SchoolTermConverter.convert(step)
      school_term = '' if school_term.to_s == SchoolTermTypes::YEARLY.to_s
      school_term
    }
  end
end
