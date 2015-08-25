class SchoolTermTypes < EnumerateIt::Base
  associate_values :bimester,
                   :trimester,
                   :semester,
                   :yearly

  sort_by :none
end
