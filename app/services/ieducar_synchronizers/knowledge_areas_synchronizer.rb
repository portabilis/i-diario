class KnowledgeAreasSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['areas']
      )
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::KnowledgeAreas.new(synchronization.to_api)
  end

  def update_records(collection)
    collection.each do |knowledge_area_record|
      KnowledgeArea.find_or_initialize_by(api_code: knowledge_area_record.id).tap do |knowledge_area|
        knowledge_area.description = knowledge_area_record.nome
        knowledge_area.sequence = knowledge_area_record.ordenamento_ac
        knowledge_area.save! if knowledge_area.changed?
      end
    end
  end
end
