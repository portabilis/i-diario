class AccessLevel < EnumerateIt::Base
  associate_values :institutional, :unit, :teacher, :parent, :student

  sort_by :none
end
