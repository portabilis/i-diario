json.array!(@unities) do |unity|
  json.id unity.id
  json.name unity.name
  json.address unity.address.to_s
  json.responsible unity.responsible
  json.phone unity.phone
end
