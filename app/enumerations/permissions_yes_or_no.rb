class PermissionsYesOrNo < EnumerateIt::Base
  associate_values :read, :change, :denied

  sort_by :none
end
