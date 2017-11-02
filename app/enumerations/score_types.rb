class ScoreTypes < EnumerateIt::Base
  associate_values :dont_use => "0",
                   :numeric => "1",
                   :concept => "2",
                   :numeric_and_concept => "3"

  sort_by :none
end
