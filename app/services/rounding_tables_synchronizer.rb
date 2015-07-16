class RoundingTablesSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch["tabelas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::RoundingTables.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      rounding_tables.delete_all

      collection.each do |record|
        rounding_tables.create!(
          api_code: record["id"],
          label: record["nome"],
          description: record["descricao"],
          value: record["valor_maximo"]
        )
      end
    end
  end

  def rounding_tables(klass = RoundingTable)
    klass
  end
end
