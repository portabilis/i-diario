class OpinionTypes < EnumerateIt::Base
  associate_values :dont_use => "0",
                   :by_step_and_discipline => "2",
                   :by_step => "3",
                   :by_year_and_discipline => "5",
                   :by_year => "6"

  sort_by :none
end
