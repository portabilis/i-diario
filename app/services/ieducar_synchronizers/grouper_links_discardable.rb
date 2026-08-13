# Descarta os vínculos (teacher_discipline_classrooms) da disciplina agrupadora de uma área de
# conhecimento, para uso quando o agrupamento de descritores é desligado no i-Educar.
#
# A disciplina agrupadora em si é mantida: planos de aula, conteúdos, notas e frequências
# históricos a referenciam (FKs sem cascade). Os vínculos são descartados (não destruídos) para
# que, se a flag for religada, o TeacherDisciplineClassroomsSynchronizer reaproveite o mesmo
# registro via `undiscard`, preservando id e auditoria.
module GrouperLinksDiscardable
  private

  def discard_grouper_links(knowledge_area)
    grouper_discipline = Discipline.unscoped.find_by(
      knowledge_area_id: knowledge_area.id,
      grouper: true,
      api_code: "grouper:#{knowledge_area.id}"
    )

    return if grouper_discipline.blank?
    return if synchronized_years.empty?

    TeacherDisciplineClassroom.where(
      discipline_id: grouper_discipline.id,
      year: synchronized_years
    ).find_each(&:discard)
  end

  # Converte o parâmetro `year` — que em synchronizers `by_year: false` chega como string com
  # todos os anos ("2026,2025") — na lista de inteiros usada no `where`. Limitar o descarte aos
  # anos sincronizados preserva o acesso dos professores aos lançamentos feitos sob a disciplina
  # agrupadora em anos já encerrados.
  def synchronized_years
    @synchronized_years ||= year.to_s.split(',').map(&:to_i).reject(&:zero?)
  end
end
