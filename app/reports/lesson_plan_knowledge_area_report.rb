require "prawn/measurement_extensions"

class LessonPlanKnowledgeAreaReport
  include Prawn::View

  def self.build(entity_configuration, date_start, date_end, knowledge_area_lesson_plans, current_teacher)
    new.build(entity_configuration, date_start, date_end, knowledge_area_lesson_plans, current_teacher)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :portrait,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, date_start, date_end, knowledge_area_lesson_plans, current_teacher)
    @entity_configuration = entity_configuration
    @date_start = date_start
    @date_end = date_end
    @knowledge_area_lesson_plans = knowledge_area_lesson_plans
    @current_teacher = current_teacher
    attributes
    @gap = 10

    header
    body
    footer

    self
  end

  protected

  private

  def header

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''
    title = 'Registro de conteúdos por áreas de conhecimento'

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
      content: "#{entity_name}\n#{organ_name}\n" + "#{@knowledge_area_lesson_plans.first.lesson_plan.unity.name}",
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
      colspan: 5 
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
    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', width: 60, padding: [2, 2, 4, 4])
    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @knowledge_area_header = make_cell(content: 'Áreas de conhecimento', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @conteudo_header = make_cell(content: 'Conteúdos', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])

    @unity_cell = make_cell(content:  @knowledge_area_lesson_plans.first.lesson_plan.unity.name, size: 10, width: 240, align: :left)
    @classroom_cell = make_cell(content: @knowledge_area_lesson_plans.first.lesson_plan.classroom.description, size: 10, align: :left)
    @teacher_cell = make_cell(content: @current_teacher.name, size: 10, align: :left)
    @period_cell = make_cell(content: (@date_start == '' || @date_end == '' ? '-' : "#{@date_start} à #{@date_end}"), size: 10, align: :left)
  end


  def identification
    title_identification = [
      [@identification_header_cell]
    ]
    

    identification_headers = [
      @unity_header,
      @classroom_header,
      @teacher_header,
      @period_header
    ]

    identification_cells = []

    identification_cells << [
      @unity_cell, 
      @classroom_cell,
      @teacher_cell,
      @period_cell
    ]


    identification_table_data = [identification_headers]
    identification_table_data.concat(identification_cells)

    table(title_identification, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    table(identification_table_data, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def general_information

    title_general_information = [
      [@general_information_header_cell]
    ]

    general_information_headers = [
      @plan_date_header,
      @knowledge_area_header,
      @conteudo_header
    ]

    general_information_cells = []

    @knowledge_area_lesson_plans.each do |knowledge_area_lesson_plan|

      knowledge_area_lesson_plans_knowledge_areas = KnowledgeAreaLessonPlanKnowledgeArea.where knowledge_area_lesson_plan_id: knowledge_area_lesson_plan.id
      
      knowledge_area_ids = []

      knowledge_area_lesson_plans_knowledge_areas.each do |knowledge_area_lesson_plans_knowledge_area|
        knowledge_area_ids << knowledge_area_lesson_plans_knowledge_area.knowledge_area_id
      end

      knowledge_areas = KnowledgeArea.where id: [knowledge_area_ids]

      knowledge_area_descriptions = (knowledge_areas.map { |descriptions| descriptions}.join(", "))

      plan_date_cell = make_cell(content: knowledge_area_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 10, width: 80, align: :left)
      conteudo_cell = make_cell(content: knowledge_area_lesson_plan.lesson_plan.contents, size: 10, align: :left)
      knowledge_area_cell = make_cell(content: knowledge_area_descriptions, size: 10, width: 150, align: :left)


      general_information_cells << [
        plan_date_cell,
        knowledge_area_cell,
        conteudo_cell
      ]
    end


    general_information_table_data = [general_information_headers]
    general_information_table_data.concat(general_information_cells)
     
    move_down @gap 

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
    bounding_box([0, cursor - @gap], width: bounds.width) do
      identification
      general_information
    end
  end

  def footer
    repeat(:all) do
      draw_text("Data e hora: #{DateTime.now.strftime("%d/%m/%Y %H:%M")}", size: 8, at: [0, 0])

      draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [20, 40])
      draw_text('____________________________', size: 8, at: [137, 40])

      draw_text('Assinatura do(a) coordenador(a):', size: 8, style: :bold, at: [279, 40])
      draw_text('____________________________', size: 8, at: [407, 40])
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end  
end