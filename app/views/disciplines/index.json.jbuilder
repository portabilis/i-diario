json.array!(@disciplines) do |discipline|
  json.id discipline.id
  json.description discipline.description
  json.to_s discipline.to_s
  json.sequence discipline.sequence
  json.knowledge_area_description discipline.knowledge_area.description
  json.knowledge_area_sequence discipline.knowledge_area.sequence
end
