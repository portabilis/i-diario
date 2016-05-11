json.array!(@grades) do |grade|
  json.id grade.id
  json.description grade.description
end
