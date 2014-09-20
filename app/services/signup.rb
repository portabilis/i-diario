module Signup
  def self.factory(mod)
    "Signup::#{mod.capitalize}".constantize
  end
end
