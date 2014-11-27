json.array!(@students) do |student|
  json.id student.id
  json.name student.name
  json.api_code student.api_code
  json.api student.api?
  json.value student.name
end
