class DisciplinesSynchronizer < BaseSynchronizer
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
    disciplines.each do |discipline_record|
      Discipline.find_or_initialize_by(api_code: discipline_record.id).tap do |discipline|
        knowledge_area = knowledge_area(discipline_record.area_conhecimento_id)
        group_descriptors = knowledge_area.group_descriptors

        discipline.description = discipline_record.nome
        discipline.sequence = discipline_record.ordenamento
        discipline.knowledge_area = knowledge_area
        discipline.descriptor = group_descriptors

        discipline.save! if discipline.changed?
      end
    end
  end
end
