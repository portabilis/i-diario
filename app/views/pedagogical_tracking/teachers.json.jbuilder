json.array!(@teacher_percents) do |teacher_percents|
  json.teacher_id teacher_percents.teacher_id
  json.teacher_name teacher_percents.teacher_name
  json.frequency_percentage teacher_percents.frequency_percentage
  json.content_record_percentage teacher_percents.content_record_percentage
  json.frequency_days teacher_percents.frequency_days
  json.content_record_days teacher_percents.content_record_days
end
