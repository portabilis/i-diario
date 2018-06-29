class DisciplineTeachingPlanPdf < BaseReport
  def self.build(entity_configuration, discipline_teaching_plan)
    new.build(entity_configuration, discipline_teaching_plan)
  end

  def build(entity_configuration, discipline_teaching_plan)
    @entity_configuration = entity_configuration
    @discipline_teaching_plan = discipline_teaching_plan
    attributes

    header
    body
    footer

    self
  end

  private

  def header
    header_cell = make_cell(
      content: 'Plano de ensino por disciplina',
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

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n#{@discipline_teaching_plan.teaching_plan.unity.name}",
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
    @general_information_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 7
    )

    @class_plan_header_cell = make_cell(
      content: 'Plano de ensino',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )

    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 7)
    @unity_cell = make_cell(content: @discipline_teaching_plan.teaching_plan.unity.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 7)

    @discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 3)
    @discipline_cell = make_cell(content: @discipline_teaching_plan.discipline.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 3)

    @classroom_header = make_cell(content: 'Série', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 4)
    @classroom_cell = make_cell(content: @discipline_teaching_plan.teaching_plan.grade.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 3)
    @teacher_cell = make_cell(content: @discipline_teaching_plan.teaching_plan.teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 3)

    @year_header = make_cell(content: 'Ano', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @year_cell = make_cell(content: @discipline_teaching_plan.teaching_plan.year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @period_header = make_cell(content: 'Período escolar', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @period_cell = make_cell(content: (@discipline_teaching_plan.teaching_plan.school_term_type == SchoolTermTypes::YEARLY ? @discipline_teaching_plan.teaching_plan.school_term_type_humanize : @discipline_teaching_plan.teaching_plan.school_term_humanize), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    objective_cell_content = inline_formated_cell_header('Objetivos') + (@discipline_teaching_plan.teaching_plan.objectives.present? ? @discipline_teaching_plan.teaching_plan.objectives : '-')
    @objective_cell = make_cell(content: objective_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    content_cell_content = inline_formated_cell_header('Conteúdos') + (@discipline_teaching_plan.teaching_plan.contents.present? ? @discipline_teaching_plan.teaching_plan.contents_ordered.map(&:to_s).join(", ") : '-')
    @content_cell = make_cell(content: content_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    methodology_cell_content = inline_formated_cell_header('Metodologia') + (@discipline_teaching_plan.teaching_plan.methodology.present? ? @discipline_teaching_plan.teaching_plan.methodology : '-')
    @methodology_cell = make_cell(content: methodology_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    evaluation_cell_content = inline_formated_cell_header('Avaliação') + (@discipline_teaching_plan.teaching_plan.evaluation.present? ? @discipline_teaching_plan.teaching_plan.evaluation : '-')
    @evaluation_cell = make_cell(content: evaluation_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    reference_cell_content = inline_formated_cell_header('Referências') + (@discipline_teaching_plan.teaching_plan.references.present? ? @discipline_teaching_plan.teaching_plan.references : '-')
    @reference_cell = make_cell(content: reference_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)
  end

  def general_information
    general_information_table_data = [
      [@general_information_header_cell],
      [@unity_header],
      [@unity_cell],
      [@discipline_header, @classroom_header],
      [@discipline_cell, @classroom_cell],
      [@teacher_header, @year_header, @period_header],
      [@teacher_cell, @year_cell, @period_cell]
    ]

    table(general_information_table_data, width: bounds.width) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def class_plan
    class_plan_table_data = [
      [@class_plan_header_cell],
      [@objective_cell],
      [@content_cell],
      [@methodology_cell],
      [@evaluation_cell],
      [@reference_cell]
    ]

    table(class_plan_table_data, width: bounds.width, cell_style: { inline_format: true }) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def body
    page_content do
      general_information
      class_plan
    end
  end
end
