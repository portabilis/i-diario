# Monta as opções dos filtros do index de quadro de aulas em cascata: cada nível lista apenas os
# registros que possuem quadro de aula dentro dos filtros do nível acima (ano > escola > série).
#
# A relação recebida já vem restrita às unidades visíveis para o usuário (LessonBoardsFetcher),
# então nenhuma opção pode vazar de fora do escopo de acesso.
class LessonsBoardsFilterOptionsQuery
  def initialize(lessons_boards)
    @lessons_boards = lessons_boards.unscope(:order)
  end

  # `selected_id` mantém na lista a escola escolhida pelo usuário mesmo que ela não tenha quadro no
  # ano filtrado — sem isso, digitar um ano sem quadros apagaria a seleção de escola sem aviso.
  def unities(year: nil, selected_id: nil)
    unity_ids = scoped(year: year).distinct.pluck('classrooms.unity_id')
    unity_ids << selected_id if selected_id.present?

    Unity.where(id: unity_ids).ordered
  end

  def grades(year: nil, unity_id: nil)
    Grade.where(
      id: scoped(year: year, unity_id: unity_id).select('classrooms_grades.grade_id')
    ).ordered
  end

  def classrooms(year: nil, unity_id: nil, grade_id: nil)
    Classroom.where(
      id: scoped(year: year, unity_id: unity_id, grade_id: grade_id).select('classrooms_grades.classroom_id')
    ).ordered
  end

  private

  attr_accessor :lessons_boards

  def scoped(year: nil, unity_id: nil, grade_id: nil)
    relation = lessons_boards.joins(classrooms_grade: :classroom)
    relation = relation.where(classrooms: { year: year }) if year.present?
    relation = relation.where(classrooms: { unity_id: unity_id }) if unity_id.present?
    relation = relation.where(classrooms_grades: { grade_id: grade_id }) if grade_id.present?

    relation
  end
end
