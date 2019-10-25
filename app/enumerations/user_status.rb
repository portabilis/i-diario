class UserStatus < EnumerateIt::Base
  associate_values :pending, :active
end
