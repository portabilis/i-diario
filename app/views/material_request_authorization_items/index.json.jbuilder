json.array!(@items) do |item|
  json.id item.id
  json.quantity item.quantity
  json.material_request_authorization_id item.authorization.id

  json.material do
    json.id item.material.id
    json.description item.material.description
    json.brand item.material.brand
    json.measuring_unit item.material.measuring_unit.to_s
  end
end
