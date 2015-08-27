class Trimesters < EnumerateIt::Base
  associate_values :first_trimester,
                   :second_trimester,
                   :third_trimester

  sort_by :none
end
