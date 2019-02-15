json.array!(@unities) do |unity|
  json.id unity.id
  json.description unity.to_s
end
