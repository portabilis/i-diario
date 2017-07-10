json.array!(@lesson_plans) do |lesson_plan|
  json.id lesson_plan.id
  json.description lesson_plan.to_s
  json.classroom_name lesson_plan.classroom.to_s
  json.unity_name lesson_plan.unity.to_s
  json.contents lesson_plan.contents
end