class RoleKind < EnumerateIt::Base
  associate_values :employee, :parent, :student

  sort_by :none
end
