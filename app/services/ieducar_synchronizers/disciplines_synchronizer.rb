class DisciplinesSynchronizer < BaseSynchronizer
  include GrouperLinksDiscardable

  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['disciplinas']
      )
    )
  end

  private

  def api_class
    IeducarApi::Disciplines
  end

  def update_records(disciplines)
    preload_knowledge_areas(disciplines.map(&:area_conhecimento_id).compact)
    preload_disciplines(disciplines.map(&:id))

    disciplines.each do |discipline_record|
      (
        discipline(discipline_record.id) ||
        Discipline.new(api_code: discipline_record.id)
      ).tap do |discipline|
        knowledge_area = knowledge_area(discipline_record.area_conhecimento_id)
        group_descriptors = knowledge_area.group_descriptors

        discipline.description = discipline_record.nome
        discipline.sequence = discipline_record.ordenamento
        discipline.knowledge_area = knowledge_area
        discipline.descriptor = group_descriptors

        create_or_discard_grouper_disciplines(knowledge_area)

        discipline.save! if discipline.changed?
      end
    end
  end

  def create_or_discard_grouper_disciplines(knowledge_area)
    return if processed_knowledge_areas.include?(knowledge_area.id)

    processed_knowledge_areas << knowledge_area.id

    if knowledge_area.group_descriptors
      Discipline.unscoped.find_or_initialize_by(
        knowledge_area_id: knowledge_area.id,
        grouper: true,
        api_code: "grouper:#{knowledge_area.id}"
      ).tap do |grouper_discipline|
        grouper_discipline.description = knowledge_area.description

        grouper_discipline.save!
      end
    else
      discard_grouper_links(knowledge_area)
    end
  end

  def processed_knowledge_areas
    @processed_knowledge_areas ||= Set.new
  end
end
