class DisciplineScoreTypes < EnumerateIt::Base
  associate_values :concept => "1",
                   :numeric => "2"

  sort_by :none
end
