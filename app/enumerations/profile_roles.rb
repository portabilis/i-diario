class ProfileRoles < EnumerateIt::Base
   associate_values :admin, :parent, :servant, :student
 end
