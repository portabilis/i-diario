class Periods < EnumerateIt::Base
  associate_values :matutinal => "1",
                   :vespertine => "2",
                   :nightly => "3"

  sort_by :none
end
