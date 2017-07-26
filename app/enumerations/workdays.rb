class Workdays < EnumerateIt::Base
  associate_values :monday,
                   :tuesday,
                   :wednesday,
                   :thursday,
                   :friday

  sort_by :none

end
