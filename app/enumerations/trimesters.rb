class Trimesters < EnumerateIt::Base
  associate_values :first_trimester,
                   :second_trimester,
                   :third_trimester

  sort_by :none

  def self.key_for(value)
    values.key(value.to_i)
  end

  def self.value_for(value)
    values[value.to_sym]
  end

  private

  def self.values
    { first_trimester: 0, second_trimester: 1, third_trimester: 2 }
  end
end
