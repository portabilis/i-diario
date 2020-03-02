class TranslationGroups < EnumerateIt::Base
  associate_values :teaching_plans, :lesson_plans, :content_records

  sort_by :none
end
