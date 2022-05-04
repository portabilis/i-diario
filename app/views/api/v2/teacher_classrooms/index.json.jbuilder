json.array!(@classrooms) do |classroom|
  json.id classroom.id
  json.description classroom.description
  json.grade_id classroom.grade_ids.first
  json.year classroom.year
end
