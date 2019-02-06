class Periods < EnumerateIt::Base
  class AsObject
    attr_accessor :id, :to_s

    def initialize(id, to_s)
      @id = id
      @to_s = to_s
    end
  end

  associate_values matutinal: '1',
                   vespertine: '2',
                   nightly: '3',
                   full: '4',
                   intermediate: '5'

  sort_by :none

  def self.all
    to_a.map { |name, id| AsObject.new(id, name) }
  end
end
