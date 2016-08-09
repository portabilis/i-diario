class BiometricTypesDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2
    BiometricTypes.to_a.map { |t,v| { id: v, name: t, text: t } }.to_json
  end
end
