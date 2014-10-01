ActiveRecord::Base.extend EnumerateIt

module EnumerateIt
  class Base
    def self.to_select
      to_a.map { |arr| { id: arr[1], name: arr[0] } }
    end

    def self.to_hash
      Hash[to_a]
    end
  end
end
