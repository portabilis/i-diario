class DisciplinesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['disciplinas']
  end

  protected

  def api
    IeducarApi::Disciplines.new(synchronization.to_api)
  end

  def update_records(collection)
    collection.each do |record|
      Discipline.find_or_initialize_by(api_code: record['id']).tap do |discipline|
        discipline.description = record['nome']
        discipline.sequence = record['ordenamento']
        discipline.knowledge_area = knowledge_area(record['area_conhecimento_id'])
        discipline.save! if discipline.changed?
      end
    end
  end

  def knowledge_area(knowledge_area_id)
    @knowledge_areas ||= {}
    @knowledge_areas[knowledge_area_id] ||=
      KnowledgeArea.find_by(api_code: knowledge_area_id)
  end
end
