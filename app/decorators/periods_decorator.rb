class PeriodsDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2
    periods = Periods.to_a.map { |t,v| { id: v, name: t, text: t } }
    periods.to_json
  end
end
