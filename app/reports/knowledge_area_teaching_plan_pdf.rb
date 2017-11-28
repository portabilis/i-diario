class KnowledgeAreaTeachingPlanPdf
  include Prawn::View

  def self.build(entity_configuration, knowledge_area_teaching_plan)
    new.build(entity_configuration, knowledge_area_teaching_plan)
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

  def build(entity_configuration, knowledge_area_teaching_plan)
    @entity_configuration = entity_configuration
    @knowledge_area_teaching_plan = knowledge_area_teaching_plan    
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
      content: 'Planos de ensino por área de conhecimento',
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
      entity_logo_cell = make_cell(content: 'aaaa', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n#{@knowledge_area_teaching_plan.teaching_plan.unity.name}",
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
    @general_information_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 6
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
    knowledge_area_lesson_plans_knowledge_areas = KnowledgeAreaTeachingPlanKnowledgeArea.where knowledge_area_teaching_plan_id: @knowledge_area_teaching_plan.id    
    knowledge_area_ids = []

    knowledge_area_lesson_plans_knowledge_areas.each do |knowledge_area_lesson_plans_knowledge_area|
      knowledge_area_ids << knowledge_area_lesson_plans_knowledge_area.knowledge_area_id
    end

    knowledge_areas = KnowledgeArea.where id: [knowledge_area_ids]

    knowledge_area_descriptions = (knowledge_areas.map { |descriptions| descriptions}.join(", "))    

    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 6)
    @unity_cell = make_cell(content: @knowledge_area_teaching_plan.teaching_plan.unity.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 6)

    @knowledge_area_header = make_cell(content: 'Áreas de conhecimento', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    @knowledge_area_cell = make_cell(content: knowledge_area_descriptions, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @classroom_header = make_cell(content: 'Série', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @classroom_cell = make_cell(content: @knowledge_area_teaching_plan.teaching_plan.grade.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @teacher_cell = make_cell(content: @knowledge_area_teaching_plan.teaching_plan.teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @year_header = make_cell(content: 'Ano', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @year_cell = make_cell(content: @knowledge_area_teaching_plan.teaching_plan.year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @period_header = make_cell(content: 'Período escolar', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @period_cell = make_cell(content: (@knowledge_area_teaching_plan.teaching_plan.school_term_type == SchoolTermTypes::YEARLY ? @knowledge_area_teaching_plan.teaching_plan.school_term_type_humanize : @knowledge_area_teaching_plan.teaching_plan.school_term_humanize), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)    

    objective_cell_content = inline_formated_cell_header('Objetivos') + (@knowledge_area_teaching_plan.teaching_plan.objectives.present? ? @knowledge_area_teaching_plan.teaching_plan.objectives : '-')
    @objective_cell = make_cell(content: objective_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    content_cell_content = inline_formated_cell_header('Conteúdos') + (@knowledge_area_teaching_plan.teaching_plan.contents.present? ? @knowledge_area_teaching_plan.teaching_plan.contents_ordered.map(&:to_s).join(", ") : '-')
    @content_cell = make_cell(content: content_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)    

    methodology_cell_content = inline_formated_cell_header('Metodologia') + (@knowledge_area_teaching_plan.teaching_plan.methodology.present? ? @knowledge_area_teaching_plan.teaching_plan.methodology : '-')
    @methodology_cell = make_cell(content: methodology_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    evaluation_cell_content = inline_formated_cell_header('Avaliação') + (@knowledge_area_teaching_plan.teaching_plan.evaluation.present? ? @knowledge_area_teaching_plan.teaching_plan.evaluation : '-')
    @evaluation_cell = make_cell(content: evaluation_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    reference_cell_content = inline_formated_cell_header('Referências') + (@knowledge_area_teaching_plan.teaching_plan.references.present? ? @knowledge_area_teaching_plan.teaching_plan.references : '-')
    @reference_cell = make_cell(content: reference_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)    
  end

  def general_information
    general_information_table_data = [
      [@general_information_header_cell],
      [@unity_header],
      [@unity_cell],
      [@knowledge_area_header, @classroom_header, @teacher_header],
      [@knowledge_area_cell, @classroom_cell, @teacher_cell],
      [@year_header, @period_header],
      [@year_cell, @period_cell]
    ]

    table(general_information_table_data, width: bounds.width) do
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
      [@objective_cell],
      [@content_cell],
      [@methodology_cell],
      [@evaluation_cell],
      [@reference_cell]
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

  def body
    bounding_box([0, 712], width: bounds.width, height: 700) do
      general_information
      class_plan      
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
