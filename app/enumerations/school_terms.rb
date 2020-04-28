class SchoolTerms < EnumerateIt::Base
  associate_values :first_bimester,
                   :second_bimester,
                   :third_bimester,
                   :fourth_bimester,
                   :first_bimester_eja,
                   :second_bimester_eja,
                   :first_trimester,
                   :second_trimester,
                   :third_trimester,
                   :first_semester,
                   :second_semester,
                   :yearly

  sort_by :none
end
