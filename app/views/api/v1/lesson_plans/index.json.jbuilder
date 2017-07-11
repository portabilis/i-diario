json.unities @unities do |unity|
  lesson_plans = LessonPlan.by_unity_id(unity.id)
                           .by_teacher_id(params[:teacher_id])
                           .current
                           .includes(classroom: :unity)
                           .ordered

  json.unity_name unity.to_s
  json.plans lesson_plans do |lesson_plan|
    json.id lesson_plan.id
    json.description lesson_plan.to_s
    json.classroom_name lesson_plan.classroom.to_s
    json.contents lesson_plan.contents
  end
end