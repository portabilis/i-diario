if @school_calendar.present?
  json.id @school_calendar.id
  json.year @school_calendar.year
  json.number_of_classes @school_calendar.number_of_classes
  json.created_at @school_calendar.created_at
  json.updated_at @school_calendar.updated_at
  json.unity_id @school_calendar.unity_id

  json.steps @school_calendar.steps do |step|
    json.start_at step.start_at
    json.end_at step.end_at
    json.start_date_for_posting step.start_date_for_posting
    json.end_date_for_posting step.end_date_for_posting
  end
else
  json.nil!
end
