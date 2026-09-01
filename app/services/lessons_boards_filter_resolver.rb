# Resolve os filtros do index de quadro de aulas em cascata: ano > escola > série > turma.
# Cada nível é resolvido depois que o nível acima foi validado, e o valor que não vale mais é
# descartado. O chamador só lê o resultado, sem precisar conhecer essa ordem.
class LessonsBoardsFilterResolver
  # Forma única das opções dos três filtros, consumida pela view e pela resposta remota.
  FilterOption = Struct.new(:id, :name, :text)

  attr_reader :year, :unity_id, :grade_id, :classroom_id,
              :unity_options, :grade_options, :classroom_options,
              :unity_id_out_of_reach

  def initialize(search_params, fetcher:, default_year:)
    @search_params = search_params
    @fetcher = fetcher
    @default_year = default_year
    @year = ''
    @unity_id = ''
    @grade_id = ''
    @classroom_id = ''
  end

  def resolve
    read_search_params

    resolve_unity
    resolve_grade
    resolve_classroom

    self
  end

  # Valores que filtram a listagem. O ano vai como número: ano incompleto ("202") filtra e não traz
  # nada, e texto não numérico estouraria a consulta, que só aceita inteiro.
  def to_filter_params
    {
      by_year: filter_year,
      by_unity: unity_id,
      by_grade: grade_id,
      by_classroom: classroom_id
    }.with_indifferent_access
  end

  # Valores exibidos nos campos: o ano volta como foi digitado.
  def to_form_params
    {
      by_year: year,
      by_unity: unity_id,
      by_grade: grade_id,
      by_classroom: classroom_id
    }.with_indifferent_access
  end

  private

  attr_reader :search_params, :fetcher, :default_year

  # Sem `search` (primeiro acesso), o filtro é o ano do perfil. Com o campo enviado vazio, a
  # listagem traz todos os anos.
  def read_search_params
    unless search_params.respond_to?(:permit)
      @year = default_year.to_s
      return
    end

    permitted = search_params.permit(:by_year, :by_unity, :by_grade, :by_classroom).to_h

    @year = sanitize(permitted['by_year'])
    @unity_id = sanitize(permitted['by_unity'])
    @grade_id = sanitize(permitted['by_grade'])
    @classroom_id = sanitize(permitted['by_classroom'])
  end

  def sanitize(value)
    value = value.to_s.strip

    value == Select2Input::EMPTY_ELEMENT_ID ? '' : value
  end

  def filter_year
    return '' if year.blank?

    year.to_i.to_s
  end

  # A escola só é descartada quando está fora do acesso do usuário. Não ter quadro no ano filtrado
  # não invalida a escolha: descartá-la apagaria a seleção sem aviso.
  def resolve_unity
    if unity_id.present? && !fetcher.unities.exists?(id: unity_id)
      @unity_id_out_of_reach = unity_id
      @unity_id = ''
    end

    @unity_options = build_options(query.unities(year: filter_year, selected_id: unity_id))
  end

  def resolve_grade
    @grade_options = build_options(query.grades(year: filter_year, unity_id: unity_id))

    @grade_id = '' unless option_ids(grade_options).include?(grade_id)
  end

  def resolve_classroom
    classrooms = query.classrooms(year: filter_year, unity_id: unity_id, grade_id: grade_id)

    @classroom_options = build_options(classrooms) { |classroom| classroom_label(classroom) }

    @classroom_id = '' unless option_ids(classroom_options).include?(classroom_id)
  end

  # Sem filtro de ano a lista mistura anos, então o rótulo leva o ano para diferenciar turmas
  # de mesmo nome.
  def classroom_label(classroom)
    return classroom.to_s if year.present?

    "#{classroom.description} - #{classroom.year}"
  end

  def query
    @query ||= LessonsBoardsFilterOptionsQuery.new(fetcher.lesson_boards)
  end

  def build_options(records)
    records.map do |record|
      label = block_given? ? yield(record) : record.to_s

      FilterOption.new(record.id, label, label)
    end
  end

  def option_ids(records)
    records.map { |record| record.id.to_s }
  end
end
