json.array!(@knowledge_areas) do |knowledge_area|
  json.id knowledge_area.id
  json.description knowledge_area.description
end
