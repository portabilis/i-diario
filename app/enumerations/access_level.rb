class AccessLevel < EnumerateIt::Base
  associate_values :administrator, :employee, :teacher, :parent, :student

  sort_by :none
end
