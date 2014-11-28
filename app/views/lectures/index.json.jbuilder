json.array!(@lectures) do |lecture|
  json.label lecture.label
  json.id lecture.id
  json.name lecture.name
  json.series lecture.grades do |grade|
    json.id grade.id
    json.name grade.name
    json.label grade.label
  end
end
