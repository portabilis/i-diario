class SchoolTerms < EnumerateIt::Base
  associate_values :first_bimester,
                   :second_bimester,
                   :third_bimester,
                   :fourth_bimester,
                   :first_trimester,
                   :second_trimester,
                   :third_trimester,
                   :first_semester,
                   :second_semester,
                   :yearly

  sort_by :none
end
