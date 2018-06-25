json.array!(@classrooms) do |classroom|
  json.id classroom.id
  json.description classroom.description
  if params[:include_unity]
    json.unity do
      json.name classroom.unity.name
      json.id classroom.unity.id
    end
  end
end
