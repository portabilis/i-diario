json.unities @unities do |unity|
  json.unity_name unity.to_s
  json.unity_id unity.id

  school_calendar = CurrentSchoolCalendarFetcher.new(unity, nil).fetch

  if school_calendar.present?
    teaching_plans = TeachingPlan.by_unity_id(unity.id)
                                 .by_teacher_id(params[:teacher_id])
                                 .by_year(school_calendar.year)
                                 .includes(:unity)

    json.plans teaching_plans do |teaching_plan|
      next if teaching_plan.discipline_teaching_plan.nil? && teaching_plan.knowledge_area_teaching_plan.nil?

      json.id teaching_plan.id
      json.year teaching_plan.year
      json.unity_name unity.to_s
      json.unity_id unity.id
      json.description teaching_plan.to_s
      json.grade_name teaching_plan.grade.to_s
      json.grade_id teaching_plan.grade_id
      json.period teaching_plan.school_term_type_step_humanize
      json.contents teaching_plan.contents
      json.objectives teaching_plan.objectives
      json.evaluation teaching_plan.evaluation
      json.activities teaching_plan.methodology
      json.bibliography teaching_plan.references

      if teaching_plan.discipline_teaching_plan
        discipline_id = teaching_plan.discipline_teaching_plan.discipline_id
      elsif teaching_plan.knowledge_area_teaching_plan
        knowledge_areas = teaching_plan.knowledge_area_teaching_plan.knowledge_areas.ordered
      end
      json.knowledge_areas knowledge_areas
      json.discipline_id discipline_id
    end
  else
    json.plans []
  end
end
