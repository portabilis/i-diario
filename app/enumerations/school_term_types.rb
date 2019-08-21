class SchoolTermTypes < EnumerateIt::Base
  associate_values :bimester,
                   :bimester_eja,
                   :trimester,
                   :semester,
                   :yearly

  sort_by :none
end
