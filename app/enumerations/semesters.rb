class Semesters < EnumerateIt::Base
  associate_values :first_semester,
                   :second_semester

  sort_by :none
end
