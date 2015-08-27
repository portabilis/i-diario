class Bimesters < EnumerateIt::Base
  associate_values :first_bimester,
                   :second_bimester,
                   :third_bimester,
                   :fourth_bimester

  sort_by :none
end
