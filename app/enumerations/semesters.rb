class Semesters < EnumerateIt::Base
  associate_values :first,
                   :second

  sort_by :none
end
