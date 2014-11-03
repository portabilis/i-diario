json.array!(@grades) do |grade|
  json.id grade.id
  json.name grade.name
  json.id_and_name = grade.id_and_name
end
