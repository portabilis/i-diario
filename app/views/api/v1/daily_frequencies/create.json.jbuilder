json.array!(@students) do |student|
  json.daily_frequency_id student.daily_frequency_id
  json.id student.id
  json.student_id student.student_id
  json.student_name student.student.name
  json.present student.present
  json.dependence student.dependence
end