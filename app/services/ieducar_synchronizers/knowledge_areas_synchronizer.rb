class KnowledgeAreasSynchronizer < BaseSynchronizer
  include GrouperLinksDiscardable

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
    preload_knowledge_areas(knowledge_areas.map(&:id))

    knowledge_areas.each do |knowledge_area_record|
      (
        knowledge_area(knowledge_area_record.id) ||
        KnowledgeArea.new(api_code: knowledge_area_record.id)
      ).tap do |knowledge_area|
        knowledge_area.description = knowledge_area_record.nome
        knowledge_area.sequence = knowledge_area_record.ordenamento_ac
        knowledge_area.group_descriptors = knowledge_area_record.agrupar_descritores

        # A transição precisa ser lida ANTES do `save!`, que zera o dirty tracking
        group_descriptors_disabled = knowledge_area.group_descriptors_changed?(from: true, to: false)

        # Quando o agrupamento de descritores é desligado no i-Educar, descarta os vínculos da
        # disciplina agrupadora, que deixam de valer com a flag desabilitada. Na mesma transação
        # do `save!`: se o descarte falhar, o rollback restaura a flag e a transição volta a ser
        # detectada no retry do worker
        ActiveRecord::Base.transaction do
          knowledge_area.save! if knowledge_area.changed?

          discard_grouper_links(knowledge_area) if group_descriptors_disabled
        end

        knowledge_area.discard_or_undiscard(knowledge_area_record.deleted_at.present?)
      end
    end
  end
end
