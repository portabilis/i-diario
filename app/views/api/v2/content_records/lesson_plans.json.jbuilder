json.lesson_plans @lesson_plans do |lesson_plan|
  json.id lesson_plan.id
  json.unity_name lesson_plan.classroom.unity.to_s
  json.description lesson_plan.to_s
  json.classroom_name lesson_plan.classroom.to_s
  json.contents lesson_plan.contents do |content|
    json.id content.id
    json.description content.description
  end

  if lesson_plan.knowledge_area_lesson_plan
    knowledge_areas = lesson_plan.knowledge_area_lesson_plan.knowledge_areas
  elsif lesson_plan.discipline_lesson_plan
    discipline_id = lesson_plan.discipline_lesson_plan.discipline_id
  end
  json.knowledge_areas knowledge_areas
  json.discipline_id discipline_id
  json.grade_id lesson_plan.first_grade.id
  json.unity_id lesson_plan.classroom.unity.id
  json.classroom_id lesson_plan.classroom_id
  json.start_at lesson_plan.start_at
  json.end_at lesson_plan.end_at
end
