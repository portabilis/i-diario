class Bimesters < EnumerateIt::Base
  associate_values :first_bimester,
                   :second_bimester,
                   :third_bimester,
                   :fourth_bimester

  sort_by :none

  def self.key_for(value)
    values.key(value.to_i)
  end

  def self.value_for(value)
    values[value.to_sym]
  end

  private

  def self.values
    { first_bimester: 0, second_bimester: 1, third_bimester: 2, fourth_bimester: 3 }
  end
end
