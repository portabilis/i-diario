class KnowledgeAreasSynchronizer < BaseSynchronizer
  def synchronize!
    update_knowledge_areas(
      HashDecorator.new(
        api.fetch['areas']
      )
    )
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

        if knowledge_area.group_descriptors
          Discipline.find_or_initialize_by(
            knowledge_area_id: knowledge_area.id,
            grouper: true,
            api_code: '0' * knowledge_area.id
          # api_code tem indice de unicidade, então não consigo deixar fixo o 0
          # pois dá problema de duplicidade, desta forma que eu fiz, ele sempre multiplica os zeros pelo id, ou seja,
          # id 1 tem 0, id 2 tem 00 e por aí vai, desta forma nunca havera duplicidade.
          # (talvez pensar alguma maneira melhor de fazer isso, o comentário irei remover antes do PR subir)
          ).tap do |grouper_discipline|
            grouper_discipline.description = knowledge_area.description

            grouper_discipline.save! if grouper_discipline.changed?
          end
        else
          Discipline.find_by(
            knowledge_area_id: knowledge_area.id,
            grouper: true,
            api_code: '0'
          )&.destroy
        end


        knowledge_area.discard_or_undiscard(knowledge_area_record.deleted_at.present?)
      end
    end
  end
end
