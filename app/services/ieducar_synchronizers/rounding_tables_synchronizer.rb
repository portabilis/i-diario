class RoundingTablesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['tabelas']
      )
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::RoundingTables.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      RoundingTableValue.delete_all

      collection.each do |rounding_table_record|
        rounding_table = RoundingTable.find_by(api_code: rounding_table_record.id)

        if rounding_table.present?
          rounding_table.update(
            name: rounding_table_record.nome
          )
        else
          rounding_table = RoundingTable.create!(
            api_code: rounding_table_record.id,
            name: rounding_table_record.nome
          )
        end

        rounding_table_record.valores.each do |rounding_table_value_record|
          RoundingTableValue.create!(
            rounding_table_api_code: rounding_table_record.id,
            rounding_table_id: rounding_table.id,
            label: rounding_table_value_record.rotulo,
            description: rounding_table_value_record.descricao,
            value: rounding_table_value_record.valor_maximo,
            exact_decimal_place: rounding_table_value_record.casa_decimal_exata,
            action: rounding_table_value_record.acao
          )
        end
      end
    end
  end
end
