json.array!(@lectures) do |lecture|
  json.id lecture.id
  json.name lecture.name
  json.id_and_name = lecture.id_and_name
end
