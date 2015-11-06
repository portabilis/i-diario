class DisciplineLessonPlanPdf
  include Prawn::View

  def self.build(entity_configuration, discipline_lesson_plan)
    new.build(entity_configuration, discipline_lesson_plan)
  end

  def initialize
    @document = Prawn::Document.new(
      page_size: 'A4',
      page_layout: :portrait,
      left_margin: 5.mm,
      right_margin: 5.mm,
      top_margin: 5.mm,
      bottom_margin: 5.mm)
  end

  def build(entity_configuration, discipline_lesson_plan)
    @entity_configuration = entity_configuration
    @discipline_lesson_plan = discipline_lesson_plan
    @gap = 10

    header
    body
    footer

    self
  end

  private

  def header
    header_cell = make_cell(
      content: 'Planos de aula por disciplina',
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
      content: "#{entity_name}\n#{organ_name}\n#{@discipline_lesson_plan.lesson_plan.unity.name}",
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

    repeat(:all) do
      table(table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def body
    general_information_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )

    classes = (!@discipline_lesson_plan.classes ? '' : @discipline_lesson_plan.classes.map { |classes| classes}.join(", "))


    unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    unity_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.unity.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    plan_date_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    classroom_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    class_header = make_cell(content: 'Aulas', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    class_cell = make_cell(content: classes.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    discipline_cell = make_cell(content: @discipline_lesson_plan.discipline.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)


    general_information_table_data = [
      [general_information_header_cell],
      [unity_header],
      [unity_cell],
      [discipline_header, classroom_header],
      [discipline_cell, classroom_cell],
      [plan_date_header, class_header],
      [plan_date_cell, class_cell]
    ]

    bounding_box([0, cursor - @gap], width: bounds.width) do
      table(general_information_table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end

    class_plan_header_cell = make_cell(
      content: 'Plano de aula',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4 
    )


    conteudo_header = make_cell(content: 'Conteúdos', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    conteudo_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.contents.present? ? @discipline_lesson_plan.lesson_plan.contents : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    objective_header = make_cell(content: 'Objetivos', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    objective_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.objectives.present? ? @discipline_lesson_plan.lesson_plan.objectives : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    resource_header = make_cell(content: 'Recursos', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    resource_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.resources.present? ? @discipline_lesson_plan.lesson_plan.resources : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    evaluation_header = make_cell(content: 'Avaliação', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    evaluation_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.evaluation.present? ? @discipline_lesson_plan.lesson_plan.evaluation : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    bibliography_header = make_cell(content: 'Referências', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    bibliography_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.bibliography.present? ? @discipline_lesson_plan.lesson_plan.bibliography : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    activitie_header = make_cell(content: 'Atividades/metodologia', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    activitie_cell = make_cell(content: (@discipline_lesson_plan.lesson_plan.activities.present? ? @discipline_lesson_plan.lesson_plan.activities : '-'), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    class_plan_table_data = [
      [class_plan_header_cell],
      [conteudo_header],
      [conteudo_cell],
      [activitie_header],
      [activitie_cell],
      [objective_header],
      [objective_cell],
      [resource_header],
      [resource_cell],
      [evaluation_header],
      [evaluation_cell],
      [bibliography_header],
      [bibliography_cell]
    ]

    bounding_box([0, cursor - @gap], width: bounds.width) do
      table(class_plan_table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end

    additional_information_header_cell = make_cell(
      content: 'Informações adicionais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4 
    )

    opinion_header = make_cell(content: 'Parecer', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    opinion_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.opinion, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)


    additional_information_table_data = [
      [additional_information_header_cell],
      [opinion_header],
      [opinion_cell]
    ]

    if @discipline_lesson_plan.lesson_plan.opinion.present?
      bounding_box([0, cursor - @gap], width: bounds.width) do
        table(additional_information_table_data, width: bounds.width) do
          cells.border_width = 0.25
          row(0).border_top_width = 0.25
          row(-1).border_bottom_width = 0.25
          column(0).border_left_width = 0.25
          column(-1).border_right_width = 0.25
        end
      end
    end
    
  end

  def footer
    repeat(:all) do
      draw_text("Data e hora: #{DateTime.now.strftime("%d/%m/%Y %H:%M")}", size: 8, at: [0, 0])
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end
end