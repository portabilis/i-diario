class KnowledgeAreaLessonPlanPdf
  include Prawn::View

  def self.build(entity_configuration, knowledge_area_lesson_plan, current_teacher)
    new.build(entity_configuration, knowledge_area_lesson_plan, current_teacher)
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

  def build(entity_configuration, knowledge_area_lesson_plan, current_teacher)
    @entity_configuration = entity_configuration
    @knowledge_area_lesson_plan = knowledge_area_lesson_plan
    @current_teacher = current_teacher
    @gap = 8
    attributes

    header
    body
    footer

    self
  end

  private

  def header
    header_cell = make_cell(
      content: 'Planos de aula por área de conhecimento',
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
      content: "#{entity_name}\n#{organ_name}\n#{@knowledge_area_lesson_plan.lesson_plan.unity.name}",
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


  def attributes
    @identification_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )

    @class_plan_header_cell = make_cell(
      content: ' Plano de aula',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )

    @additional_information_header_cell = make_cell(
      content: 'Informações adicionais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )

    knowledge_area_lesson_plans_knowledge_areas = KnowledgeAreaLessonPlanKnowledgeArea.where knowledge_area_lesson_plan_id: @knowledge_area_lesson_plan.id

    knowledge_area_ids = []

    knowledge_area_lesson_plans_knowledge_areas.each do |knowledge_area_lesson_plans_knowledge_area|
      knowledge_area_ids << knowledge_area_lesson_plans_knowledge_area.knowledge_area_id
    end

    knowledge_areas = KnowledgeArea.where id: [knowledge_area_ids]

    knowledge_area_descriptions = (knowledge_areas.map { |descriptions| descriptions}.join(", "))

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @teacher_cell = make_cell(content: @current_teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 4)
    @unity_cell = make_cell(content: @knowledge_area_lesson_plan.lesson_plan.unity.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    @start_at_header = make_cell(content: 'Data inicial', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4])
    @start_at_cell = make_cell(content: @knowledge_area_lesson_plan.lesson_plan.start_at.strftime("%d/%m/%Y"), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4])

    @end_at_header = make_cell(content: 'Data final', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4])
    @end_at_cell = make_cell(content: @knowledge_area_lesson_plan.lesson_plan.end_at.strftime("%d/%m/%Y"), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4])

    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    @classroom_cell = make_cell(content: @knowledge_area_lesson_plan.lesson_plan.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @knowledge_area_header = make_cell(content: 'Áreas de conhecimento', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    @knowledge_area_cell = make_cell(content: knowledge_area_descriptions, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    conteudo_cell_content = inline_formated_cell_header('Conteúdos') + (@knowledge_area_lesson_plan.lesson_plan.contents.present? ? @knowledge_area_lesson_plan.lesson_plan.contents : '-')
    @conteudo_cell = make_cell(content:  conteudo_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    objective_cell_content = inline_formated_cell_header('Objetivos') + (@knowledge_area_lesson_plan.lesson_plan.objectives.present? ? @knowledge_area_lesson_plan.lesson_plan.objectives : '-')
    @objective_cell = make_cell(content: objective_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    resource_cell_content = inline_formated_cell_header('Recursos') + (@knowledge_area_lesson_plan.lesson_plan.resources.present? ? @knowledge_area_lesson_plan.lesson_plan.resources : '-')
    @resource_cell = make_cell(content: resource_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    evaluation_cell_content = inline_formated_cell_header('Avaliação') + (@knowledge_area_lesson_plan.lesson_plan.evaluation.present? ? @knowledge_area_lesson_plan.lesson_plan.evaluation : '-')
    @evaluation_cell = make_cell(content: evaluation_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    bibliography_cell_content = inline_formated_cell_header('Referências') + (@knowledge_area_lesson_plan.lesson_plan.bibliography.present? ? @knowledge_area_lesson_plan.lesson_plan.bibliography : '-')
    @bibliography_cell = make_cell(content: bibliography_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    activitie_cell_content = inline_formated_cell_header('Atividades/metodologia') + (@knowledge_area_lesson_plan.lesson_plan.activities.present? ? @knowledge_area_lesson_plan.lesson_plan.activities : '-' )
    @activitie_cell = make_cell(content: activitie_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    opinion_cell_content = inline_formated_cell_header('Parecer') + @knowledge_area_lesson_plan.lesson_plan.opinion.to_s
    @opinion_cell = make_cell(content: opinion_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)
  end

  def identification
    identification_table_data = [
      [@identification_header_cell],
      [@unity_header],
      [@unity_cell],
      [@knowledge_area_header, @classroom_header],
      [@knowledge_area_cell, @classroom_cell],
      [@teacher_header, @start_at_header, @end_at_header],
      [@teacher_cell, @start_at_cell, @end_at_cell]
    ]

    table(identification_table_data, width: bounds.width) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def class_plan
    class_plan_table_data = [
      [@class_plan_header_cell],
      [@conteudo_cell],
      [@activitie_cell],
      [@objective_cell],
      [@resource_cell],
      [@evaluation_cell],
      [@bibliography_cell]
    ]

    move_down @gap
    table(class_plan_table_data, width: bounds.width, cell_style: { inline_format: true }) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def additional_information
    additional_information_table_data = [
      [@additional_information_header_cell],
      [@opinion_cell]
    ]

    if @knowledge_area_lesson_plan.lesson_plan.opinion.present?
      start_new_page if cursor < 45
      table(additional_information_table_data, width: bounds.width, cell_style: { inline_format: true }) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def body
    bounding_box([0, 728], width: bounds.width, height: 700) do
      identification
      class_plan
      additional_information
    end
  end

  def footer
    repeat(:all) do
      draw_text("Data e hora: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}", size: 8, at: [0, 0])
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end

  def inline_formated_cell_header(text)
    "<font size='8'><b>#{text}</b></font>\n"
  end
end
