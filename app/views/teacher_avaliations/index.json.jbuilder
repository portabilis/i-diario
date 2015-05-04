json.array!(@avaliations) do |avaliation|
  json.id avaliation.id
  json.description avaliation.description_to_teacher
end
