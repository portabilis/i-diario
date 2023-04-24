class RequireDailyActivitiesRecordTypes < EnumerateIt::Base
  associate_values :does_not_require,
                   :on_discipline_content_records,
                   :on_knowledge_area_content_records,
                   :always

  sort_by :none
end
