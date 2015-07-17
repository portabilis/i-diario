class FrequencyTypes < EnumerateIt::Base
  associate_values :general => "1",
                   :by_discipline => "2"

  sort_by :none
end
