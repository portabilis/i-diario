if @class_numbers.present?
  json.array!(@students) do |student|
    json.student_id student[:student_id]
    json.student_name student[:student_name]
    json.dependence student[:dependence]

    json.frequencies student[:daily_frequencies].each do |daily_frequency_student|
      json.daily_frequency_id daily_frequency_student.daily_frequency_id
      json.present daily_frequency_student.present
    end
  end
else
  json.array!(@students) do |student|
    json.daily_frequency_id student.daily_frequency_id
    json.id student.id
    json.student_id student.student_id
    json.student_name student.student.name
    json.present student.present
    json.dependence student.dependence
  end
end
