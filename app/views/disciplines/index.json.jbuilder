json.array!(@disciplines) do |discipline|
  json.id discipline.id
  json.description discipline.description
  json.knowledge_area_description discipline.knowledge_area.description
end
