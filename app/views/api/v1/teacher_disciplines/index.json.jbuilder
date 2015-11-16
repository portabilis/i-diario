json.array!(@disciplines) do |discipline|
  json.id discipline.id
  json.description discipline.description
end
