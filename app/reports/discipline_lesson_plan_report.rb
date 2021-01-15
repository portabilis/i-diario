class DisciplineLessonPlanReport < BaseReport
  def self.build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
    new.build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
  end

  def build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
    @entity_configuration = entity_configuration
    @date_start = date_start
    @date_end = date_end
    @discipline_lesson_plans = discipline_lesson_plan
    @current_teacher = current_teacher
    attributes

    header
    body
    footer

    self
  end

  private

  def header
    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''
    title =  'Registros de conteúdos por disciplina - Planos de aula'

    header_cell = make_cell(
      content: title,
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    begin
      entity_logo_cell = make_cell(
        image: open(@entity_configuration.logo.url),
        fit: [50, 50],
        width: 70,
        rowspan: 4,
        position: :center,
        vposition: :center
      )
    rescue
      entity_logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n" + "#{@discipline_lesson_plans.first.lesson_plan.unity.name}",
      size: 12,
      leading: 1.5,
      align: :center,
      valign: :center,
      rowspan: 4,
      padding: [6, 0, 8, 0]
    )

    table_data = [
      [header_cell],
      [
        entity_logo_cell,
        entity_organ_and_unity_cell
      ]
    ]

    page_header do
      table(table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def attributes
    @identification_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    @general_information_header_cell = make_cell(
      content: 'Informações gerais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 5
    )

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4])
    @start_at_header = make_cell(content: 'Data inicial', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', width: 60, padding: [2, 2, 4, 4])
    @end_at_header = make_cell(content: 'Data final', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', width: 60, padding: [2, 2, 4, 4])
    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @conteudo_header = make_cell(content: Translator.t('activerecord.attributes.discipline_content_record.contents'), size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])

    @unity_cell = make_cell(content:  @discipline_lesson_plans.first.lesson_plan.unity.name, borders: [:bottom, :left, :right], size: 10, width: 240, align: :left, padding: [0, 2, 4, 4], colspan: 2)
    @discipline_cell = make_cell(content: @discipline_lesson_plans.first.discipline.to_s, borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
    @classroom_cell = make_cell(content: @discipline_lesson_plans.first.lesson_plan.classroom.description, borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
    @teacher_cell = make_cell(content: @current_teacher.name, borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
    @period_cell = make_cell(content: (@date_start == '' || @date_end == '' ? '-' : "#{@date_start} a #{@date_end}"), borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
  end

  def identification
    identification_table_data = [
      [@identification_header_cell],
      [@unity_header],
      [@unity_cell],
      [@discipline_header, @classroom_header],
      [@discipline_cell, @classroom_cell],
      [@teacher_header, @period_header],
      [@teacher_cell, @period_cell]
    ]

    table(identification_table_data, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def general_information
    title_general_information = [
      [@general_information_header_cell]
    ]

    general_information_headers = [
      @start_at_header,
      @end_at_header,
      @conteudo_header
    ]

    general_information_cells = []

    @discipline_lesson_plans.each do |discipline_lesson_plan|
      start_at_cell = make_cell(content: discipline_lesson_plan.lesson_plan.start_at.strftime("%d/%m/%Y"), size: 10, align: :left)
      end_at_cell = make_cell(content: discipline_lesson_plan.lesson_plan.end_at.strftime("%d/%m/%Y"), size: 10, align: :left)
      conteudo_cell = make_cell(content: discipline_lesson_plan.lesson_plan.contents_ordered.map(&:to_s).join(", "), size: 10, align: :left)

      general_information_cells << [
        start_at_cell,
        end_at_cell,
        conteudo_cell
      ]
    end

    general_information_table_data = [general_information_headers]
    general_information_table_data.concat(general_information_cells)

    table(title_general_information, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    table(general_information_table_data, row_colors: ['DEDEDE', 'FFFFFF'], width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def body
    page_content do
      identification
      general_information
      signatures
    end
  end

  def signatures
    start_new_page if cursor < 45

    move_down 30
    text_box("______________________________________________\nProfessor(a)", size: 10, align: :center, at: [0, cursor], width: 260)
    text_box("______________________________________________\nCoordenador(a)/diretor(a)", size: 10, align: :center, at: [306, cursor], width: 260)
  end
end
