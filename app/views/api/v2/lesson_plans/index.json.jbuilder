json.unities @unities do |unity|
  lesson_plans = LessonPlan.by_unity_id(unity.id)
                           .by_teacher_id(params[:teacher_id])
                           .current
                           .includes(classroom: :unity)
                           .ordered

  json.unity_name unity.to_s
  json.plans lesson_plans do |lesson_plan|
    json.id lesson_plan.id
    json.unity_name unity.to_s
    json.description lesson_plan.to_s
    json.classroom_name lesson_plan.classroom.to_s
    json.period lesson_plan.classroom.period_humanized
    json.contents lesson_plan.contents.order_by_id
    json.objectives lesson_plan.objectives
    json.resources lesson_plan.resources
    json.evaluation lesson_plan.evaluation
    json.bibliography lesson_plan.bibliography
    json.opinion lesson_plan.opinion
    json.activities lesson_plan.activities

    if lesson_plan.knowledge_area_lesson_plan
      knowledge_areas = lesson_plan.knowledge_area_lesson_plan.knowledge_areas.ordered
    end
    json.knowledge_areas knowledge_areas
    json.start_at lesson_plan.start_at
    json.end_at lesson_plan.end_at
  end
end
