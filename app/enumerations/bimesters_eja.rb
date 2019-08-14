class BimestersEja < EnumerateIt::Base
  associate_values :first_bimester_eja,
                   :second_bimester_eja

  sort_by :none

  class << self
    def key_for(value)
      values.key(value.to_i)
    end

    def value_for(value)
      values[value.to_sym]
    end

    private

    def values
      { first_bimester_eja: 0, second_bimester_eja: 1 }
    end
  end
end
