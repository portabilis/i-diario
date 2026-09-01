# Monta as opções dos filtros do index de quadro de aulas em cascata: cada nível lista apenas os
# registros com quadro de aula dentro dos filtros do nível acima (ano > escola > série).
#
# As opções saem da relação recebida; restringi-la às escolas visíveis cabe ao chamador.
class LessonsBoardsFilterOptionsQuery
  def initialize(lessons_boards)
    @lessons_boards = lessons_boards.unscope(:order)
  end

  # `selected_id` entra na lista mesmo sem quadro no ano filtrado, para não apagar a escola que o
  # usuário escolheu. Ele não passa pela relação, então cabe ao chamador garantir que está dentro
  # do acesso do usuário.
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

  attr_reader :lessons_boards

  def scoped(year: nil, unity_id: nil, grade_id: nil)
    relation = lessons_boards.joins(classrooms_grade: :classroom)
    relation = relation.where(classrooms: { year: year }) if year.present?
    relation = relation.where(classrooms: { unity_id: unity_id }) if unity_id.present?
    relation = relation.where(classrooms_grades: { grade_id: grade_id }) if grade_id.present?

    relation
  end
end
