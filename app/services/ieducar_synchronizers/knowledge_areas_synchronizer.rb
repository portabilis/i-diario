class KnowledgeAreasSynchronizer < BaseSynchronizer
  def synchronize!
    update_knowledge_areas(
      HashDecorator.new(
        api.fetch['areas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::KnowledgeAreas
  end

  def update_knowledge_areas(knowledge_areas)
    knowledge_areas.each do |knowledge_area_record|
      KnowledgeArea.with_discarded.find_or_initialize_by(
        api_code: knowledge_area_record.id
      ).tap do |knowledge_area|
        knowledge_area.description = knowledge_area_record.nome
        knowledge_area.sequence = knowledge_area_record.ordenamento_ac
        knowledge_area.group_descriptors = knowledge_area_record.agrupar_descritores
        knowledge_area.save! if knowledge_area.changed?

        knowledge_area.discard_or_undiscard(knowledge_area_record.deleted_at.present?)
      end
    end
  end
end
