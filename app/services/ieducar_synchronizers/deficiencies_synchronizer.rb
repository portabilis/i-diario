class DeficienciesSynchronizer < BaseSynchronizer
  def synchronize!
    update_deficiencies(
      HashDecorator.new(
        api.fetch['deficiencias']
      )
    )

    finish_worker
  end

  protected

  def api_class
    IeducarApi::Deficiencies
  end

  def update_deficiencies(deficiencies)
    ActiveRecord::Base.transaction do
      deficiencies.each do |deficiency_record|
        Deficiency.find_or_initialize_by(api_code: deficiency_record.id).tap do |deficiency|
          deficiency.description = deficiency_record.nome

          deficiency.save! if deficiency.changed?
        end
      end
    end
  end
end
