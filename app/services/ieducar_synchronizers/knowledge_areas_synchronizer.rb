class KnowledgeAreasSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['areas']
  end

  protected

  def api
    IeducarApi::KnowledgeAreas.new(synchronization.to_api)
  end

  def update_records(collection)
    collection.each do |record|
      KnowledgeArea.find_or_initialize_by(api_code: record['id']).tap do |knowledge_area|
        knowledge_area.description = record['nome']
        knowledge_area.sequence = record['ordenamento_ac']
        knowledge_area.save! if knowledge_area.changed?
      end
    end
  end
end
