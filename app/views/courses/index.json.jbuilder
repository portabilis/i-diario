json.array!(@courses) do |course|
  json.id course.id
  json.description course.description
end
