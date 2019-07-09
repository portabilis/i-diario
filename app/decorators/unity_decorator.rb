class UnityDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2_remote(name)
    unities = Unity.search_name(name).ordered.map { |unity|
      { id: unity.id, description: unity.to_s }
    }

    unities.to_json
  end
end
