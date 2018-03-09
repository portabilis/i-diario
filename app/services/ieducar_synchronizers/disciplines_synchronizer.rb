class DisciplinesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch["disciplinas"]

    finish_worker('DisciplinesSynchronizer')
  end

  protected

  def api
    IeducarApi::Disciplines.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if discipline = disciplines.find_by(api_code: record["id"])
          discipline.update(
            description: record["nome"],
            sequence: record["ordenamento"],
            knowledge_area: KnowledgeArea.find_by(api_code: record["area_conhecimento_id"])
          )
        elsif record["nome"].present?
          disciplines.create!(
            api_code: record["id"],
            description: record["nome"],
            sequence: record["ordenamento"],
            knowledge_area: KnowledgeArea.find_by(api_code: record["area_conhecimento_id"])
          )
        end
      end
    end
  end

  def disciplines(klass = Discipline)
    klass
  end
end
