class DeficienciesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['deficiencias']
      )
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::Deficiencies.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |deficiency_record|
        deficiency = Deficiency.find_by(api_code: deficiency_record.id)

        if deficiency.present?
          deficiency.update(
            name: deficiency_record.nome
          )
        elsif deficiency_record.nome.present?
          Deficiency.create!(
            api_code: deficiency_record.id,
            name: deficiency_record.nome
          )
        end
      end
    end
  end
end
