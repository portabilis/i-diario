class RoundingTablesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['tabelas']
  end

  protected

  def api
    IeducarApi::RoundingTables.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      rounding_table_values.delete_all
      collection.each do |record|
        rounding_table = rounding_tables.find_by(api_code: record['id'])

        if rounding_table.present?
          rounding_table.update(
            name: record['nome']
          )
        else
          rounding_table = rounding_tables.create!(
            api_code: record['id'],
            name: record['nome']
          )
        end

        record['valores'].each do |api_value|
          rounding_table_values.create!(
            rounding_table_api_code: record['id'],
            rounding_table_id: rounding_table.id,
            label: api_value['rotulo'],
            description: api_value['descricao'],
            value: api_value['valor_maximo'],
            exact_decimal_place: api_value['casa_decimal_exata'],
            action: api_value['acao']
          )
        end
      end
    end
  end

  def rounding_tables(klass = RoundingTable)
    klass
  end

  def rounding_table_values(klass = RoundingTableValue)
    klass
  end
end
