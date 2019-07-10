class AbsenceJustificationAuthors < EnumerateIt::Base
  associate_values :my_justifications, :others

  sort_by :none
end
