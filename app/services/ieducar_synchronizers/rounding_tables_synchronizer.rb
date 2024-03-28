class RoundingTablesSynchronizer < BaseSynchronizer
  def synchronize!
    update_rounding_tables(
      HashDecorator.new(
        api.fetch['tabelas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::RoundingTables
  end

  def update_rounding_tables(rounding_tables)
    ActiveRecord::Base.transaction do
      rounding_tables.each do |rounding_table_record|
        RoundingTable.find_or_initialize_by(api_code: rounding_table_record.id).tap do |rounding_table|
          rounding_table.name = rounding_table_record.nome
          rounding_table.save! if rounding_table.changed?

          update_rounding_table_values(rounding_table, rounding_table_record.valores)
        end
      end
    end
  end

  def update_rounding_table_values(rounding_table, rounding_table_values)
    rounding_table.values.delete_all

    rounding_table_values.each do |rounding_table_value_record|
      RoundingTableValue.create!(
        rounding_table_api_code: rounding_table.api_code,
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
