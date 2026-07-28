# Escopo de edição do PROFESSOR no PEI.
#
# O professor só edita as seções 4/5 (planejamento curricular / avaliação periódica) do
# SEU componente: as disciplinas que leciona na turma do plano ou as áreas de conhecimento
# dessas disciplinas. As demais seções e as linhas de outros componentes ficam em leitura.
#
# Usado tanto pela view (quais componentes/linhas são editáveis) quanto pelo controller
# (trava server-side: nenhuma linha tocada pode ser de outro componente).
class IndividualizedEducationalPlanTeacherComponentPermission
  def initialize(teacher, iep)
    @teacher = teacher
    @iep = iep
  end

  # Congelados: são o conjunto de autorização e também são entregues à view — o freeze
  # impede que uma referência entregue mute o que decide a posse de componente.
  def disciplines
    @disciplines ||= Discipline.by_teacher_and_classroom(@teacher.id, [@iep.classroom_id]).ordered.to_a.freeze
  end

  def knowledge_areas
    @knowledge_areas ||=
      KnowledgeArea.where(id: disciplines.map(&:knowledge_area_id).uniq.compact).ordered.to_a.freeze
  end

  def owns_line?(line)
    owns?(line.discipline_id, line.knowledge_area_id)
  end

  # Toda linha das seções 4/5 alterada neste submit precisa ser do professor — tanto o valor
  # enviado quanto, para linhas existentes, o valor original no banco (impede pegar a linha de
  # outro componente e reatribuir para escapar do escopo).
  def touched_lines_authorized?
    section_lines.select { |line| touched?(line) }.all? { |line| line_authorized?(line) }
  end

  private

  # A linha das seções 4/5 pertence ao componente do professor? (por disciplina ou por área)
  def owns?(discipline_id, knowledge_area_id)
    (discipline_id.present? && discipline_ids.include?(discipline_id)) ||
      (knowledge_area_id.present? && knowledge_area_ids.include?(knowledge_area_id))
  end

  def discipline_ids
    @discipline_ids ||= disciplines.map(&:id)
  end

  def knowledge_area_ids
    @knowledge_area_ids ||= knowledge_areas.map(&:id)
  end

  # Não memoizar: precisa reler as associações depois do assign_attributes do controller
  # para enxergar linhas novas/marcadas para exclusão no submit atual.
  def section_lines
    @iep.iep_curricular_plannings + @iep.iep_periodic_evaluations
  end

  # "Tocada" cobre também a alteração só de acomodações (seção 4), que mexe nos registros de
  # junção sem marcar a própria linha como changed?.
  def touched?(line)
    line.new_record? || line.marked_for_destruction? || options_touched?(line) || content_changed?(line)
  end

  # Mudança real de conteúdo, ignorando diferenças que o round-trip do form gera sem edição:
  # nil vs "" e o \r\n que o navegador injeta em <textarea>. Sem isto, uma linha alheia que o
  # professor só ecoa (readonly) poderia ser marcada como tocada pela representação e bloqueá-lo
  # indevidamente.
  def content_changed?(line)
    line.changes.any? { |_attr, (was, now)| normalize(was) != normalize(now) }
  end

  def normalize(value)
    value.to_s.delete("\r")
  end

  # Alterou as acomodações da linha (só a seção 4 as tem): alguma opção adicionada ou removida.
  def options_touched?(line)
    return false unless line.is_a?(IepCurricularPlanning)

    line.iep_curricular_planning_options.any? { |option| option.new_record? || option.marked_for_destruction? }
  end

  def line_authorized?(line)
    current_ok = owns?(line.discipline_id, line.knowledge_area_id)
    return current_ok if line.new_record?

    original_ok = owns?(line.discipline_id_was, line.knowledge_area_id_was)
    current_ok && original_ok
  end
end
