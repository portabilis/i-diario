json.array!(@disciplines) do |discipline|
  json.id discipline.id
  json.description discipline.to_s
end
