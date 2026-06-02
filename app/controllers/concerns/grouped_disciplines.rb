module GroupedDisciplines
  extend ActiveSupport::Concern

  private

  # Exclui disciplinas não-agrupadoras de áreas de conhecimento com group_descriptors habilitado,
  # mantendo apenas a disciplina agrupadora de cada área evita entradas duplicadas nos dropdowns
  def exclude_non_grouper_disciplines(disciplines)
    grouped_ka_ids = KnowledgeArea.where(group_descriptors: true).pluck(:id)
    return disciplines if grouped_ka_ids.empty?

    kept_ids = disciplines.reject { |d|
      grouped_ka_ids.include?(d.knowledge_area_id) && !d.grouper?
    }.map(&:id)

    Discipline.where(id: kept_ids).ordered
  end
end
