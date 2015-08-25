class Trimesters < EnumerateIt::Base
  associate_values :first,
                   :second,
                   :third

  sort_by :none
end
