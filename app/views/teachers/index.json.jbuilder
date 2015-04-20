json.array!(@teachers) do |teacher|
  json.id teacher.id
  json.name teacher.name
  json.api_code teacher.api_code
  json.value teacher.name
end
