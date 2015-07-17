class ScoreTypes < EnumerateIt::Base
  associate_values :dont_use => "0",
                   :numeric => "1",
                   :concept => "2"

  sort_by :none
end
