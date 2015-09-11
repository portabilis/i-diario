class Semesters < EnumerateIt::Base
  associate_values :first_semester,
                   :second_semester

  sort_by :none

  def self.key_for(value)
    values.key(value.to_i)
  end

  def self.value_for(value)
    values[value.to_sym]
  end

  private

  def self.values
    { first_semester: 0, second_semester: 1 }
  end
end
