class StudentEnrollmentScoreTypeFilters < EnumerateIt::Base
  associate_values :numeric,
                   :concept,
                   :both

  sort_by :none
end
