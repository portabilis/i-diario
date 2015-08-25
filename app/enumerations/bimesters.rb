class Bimesters < EnumerateIt::Base
  associate_values :first,
                   :second,
                   :third,
                   :fourth

  sort_by :none
end
