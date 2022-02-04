json.content_records @content_records do |content_record|
  json.id content_record.id
  json.classroom_id content_record.classroom_id
  json.classroom_name content_record.classroom.to_s
  json.unity_id content_record.classroom.unity_id
  json.unity_name content_record.classroom.unity.to_s
  json.description content_record.to_s

  json.contents content_record.contents do |content|
    json.id content.id
    json.description content.description
  end

  if content_record.knowledge_area_content_record
    knowledge_areas = content_record.knowledge_area_content_record.knowledge_areas
  elsif content_record.discipline_content_record
    discipline_id = content_record.discipline_content_record.discipline_id
  end
  json.knowledge_areas knowledge_areas
  json.discipline_id discipline_id
  json.grade_id content_record.first_grade.id

  json.record_date content_record.record_date
end
