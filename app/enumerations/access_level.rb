class AccessLevel < EnumerateIt::Base
  associate_values :administrator, :employee, :teacher

  sort_by :none
end
