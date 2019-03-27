class DeficienciesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['deficiencias']
  end

  protected

  def api
    IeducarApi::Deficiencies.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        deficiency = deficiencies.find_by(api_code: record['id'])

        if deficiency.present?
          deficiency.update(name: record['nome'])
        elsif record['nome'].present?
          deficiencies.create!(
            api_code: record['id'],
            name: record['nome']
          )
        end
      end
    end
  end

  def deficiencies(klass = Deficiency)
    klass
  end
end
