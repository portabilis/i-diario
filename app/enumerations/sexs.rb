class Sexs < EnumerateIt::Base
  associate_values :male => "M",
                   :female => "F"

  sort_by :none
end
