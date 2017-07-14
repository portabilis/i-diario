json.unities @unities do |unity|
  teaching_plans = TeachingPlan.by_unity_id(unity.id)
                               .by_teacher_id(params[:teacher_id])
                               .includes(:unity)

  json.unity_name unity.to_s
  json.plans teaching_plans do |teaching_plan|
    json.id teaching_plan.id
    json.unity_name unity.to_s
    json.description teaching_plan.to_s
    json.grade_name teaching_plan.grade.to_s
    json.period teaching_plan.school_term_humanize
    json.contents teaching_plan.contents
    json.objectives teaching_plan.objectives
    json.evaluation teaching_plan.evaluation
    json.activities teaching_plan.methodology
    json.bibliography teaching_plan.references

    if teaching_plan.knowledge_area_teaching_plan
      knowledge_areas = teaching_plan.knowledge_area_teaching_plan.knowledge_areas
    end
    json.knowledge_areas knowledge_areas
  end
end