class Year < EnumerateIt::Base
  associate_values :yearly

  sort_by :none

  def self.key_for(value)
    values.key(value.to_i)
  end

  def self.value_for(value)
    values[value.to_sym]
  end

  private

  def self.values
    { yearly: 0 }
  end
end
