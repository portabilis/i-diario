class RequireDailyActivitiesRecordTypes < EnumerateIt::Base
  associate_values :does_not_require,
                   :require_on_discipline_content_records,
                   :require_on_knowledge_area_content_records,
                   :always_require

  sort_by :none
end
