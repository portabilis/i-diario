# Descarta os vínculos (teacher_discipline_classrooms) das disciplinas agrupadoras de uma área
# de conhecimento, para uso quando o agrupamento de descritores é desligado no i-Educar.
#
# As disciplinas agrupadoras em si são mantidas: planos de aula, conteúdos, notas e frequências
# históricos as referenciam (FKs sem cascade). Os vínculos são descartados (não destruídos) para
# que, se a flag for religada, o TeacherDisciplineClassroomsSynchronizer reaproveite o mesmo
# registro via `undiscard`, preservando id e auditoria.
#
# Requer do includer o reader `year` (disponível em BaseSynchronizer) no formato dos
# synchronizers `by_year: false` — string com todos os anos da sincronização ("2026,2025").
module GrouperLinksDiscardable
  private

  def discard_grouper_links(knowledge_area)
    # Sem filtrar por api_code: áreas com agrupadoras legadas ou duplicadas (formato antigo de
    # api_code) também precisam ter os vínculos descartados
    grouper_discipline_ids = Discipline.where(
      knowledge_area_id: knowledge_area.id,
      grouper: true
    ).pluck(:id)

    return if grouper_discipline_ids.empty?

    if synchronized_years.empty?
      Rails.logger.error(
        "[GrouperLinksDiscardable] parâmetro year vazio ou inválido (#{year.inspect}); " \
        "nenhum vínculo agrupador descartado (knowledge_area_id: #{knowledge_area.id})"
      )
      return
    end

    # Registro a registro (não update_all) para preservar validações, callbacks e auditoria;
    # find_each porque o discard tira a linha do default_scope e paginação por offset pularia registros
    TeacherDisciplineClassroom.where(
      discipline_id: grouper_discipline_ids,
      year: synchronized_years
    ).find_each do |link|
      next if link.discard

      Rails.logger.error(
        "[GrouperLinksDiscardable] falha ao descartar vínculo agrupador (id: #{link.id}, " \
        "knowledge_area_id: #{knowledge_area.id}, erros: #{link.errors.full_messages.join('; ')})"
      )
    end
  end

  # Converte o parâmetro `year` — string com os anos da sincronização ("2026,2025") — na lista
  # de inteiros usada no `where`, limitando o descarte aos anos da janela sincronizada
  def synchronized_years
    @synchronized_years ||= year.to_s.split(',').map(&:to_i).reject(&:zero?)
  end
end
