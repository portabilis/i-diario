json.array!(@classrooms) do |classroom|
  json.id classroom.id
  json.description classroom.description
end
