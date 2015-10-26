require "prawn/measurement_extensions"

class LessonPlanReport
  include Prawn::View

  def self.build(entity_configuration, date_start, date_end, discipline_lesson_plan, knowledge_area_lesson_plans)
    new.build(entity_configuration, date_start, date_end, discipline_lesson_plan, knowledge_area_lesson_plans)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :portrait,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, date_start, date_end, discipline_lesson_plan, knowledge_area_lesson_plans)
    @entity_configuration = entity_configuration
    @date_start = date_start
    @date_end = date_end
    @discipline_lesson_plans = discipline_lesson_plan
    @knowledge_area_lesson_plans = knowledge_area_lesson_plans

    header

    if @knowledge_area_lesson_plans != []
      knowledge_areas_body
    else
      discipline_body
    end

    footer

    self
  end

  protected

  private

  def header

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''
    title = @knowledge_area_lesson_plans != [] ? 'Planos de aula por área de conhecimento' : 'Planos de aula de disciplina'

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
      content: "#{entity_name}\n#{organ_name}\n" + (@knowledge_area_lesson_plans != [] ?  "#{@knowledge_area_lesson_plans.first.lesson_plan.unity.name}" : "#{@discipline_lesson_plans.first.lesson_plan.unity.name}"),
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

  def knowledge_areas_body

    general_information_header_cell = make_cell(
      content: 'Informações gerais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 6
    )


    plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    knowledge_area_header = make_cell(content: 'Áreas de conhecimento', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    conteudo_header = make_cell(content: 'Conteúdos', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)


    headers = [
      plan_date_header,
      classroom_header,
      knowledge_area_header,
      conteudo_header
    ]

    knowledge_area_cells = []

    @knowledge_area_lesson_plans.each do |knowledge_area_lesson_plan|

      knowledge_area_lesson_plans_knowledge_area = KnowledgeAreaLessonPlanKnowledgeArea.find_by knowledge_area_lesson_plan_id: knowledge_area_lesson_plan.id
      knowledge_area = KnowledgeArea.find_by id: knowledge_area_lesson_plans_knowledge_area.knowledge_area_id

      plan_date_cell = make_cell(content: knowledge_area_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 8, align: :left)
      classroom_cell = make_cell(content: knowledge_area_lesson_plan.lesson_plan.classroom.description, size: 8, align: :left)
      knowledge_area_cell = make_cell(content: knowledge_area.description, size: 8, align: :left)
      conteudo_cell = make_cell(content: knowledge_area_lesson_plan.lesson_plan.contents, size: 8, align: :left)


      knowledge_area_cells << [
        plan_date_cell,
        classroom_cell,
        knowledge_area_cell,
        conteudo_cell
      ]
    end

    data = [headers]
    data.concat(knowledge_area_cells)

    bounding_box([0, 727], width: bounds.width) do
      table(data, row_colors: ['DEDEDE', 'FFFFFF'], width: bounds.width, header: true) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def discipline_body
    general_information_header_cell = make_cell(
      content: 'Informações gerais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4 
    )


    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    class_header = make_cell(content: 'Aulas', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
    conteudo_header = make_cell(content: 'Conteúdos', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)

    headers = [
      discipline_header,
      plan_date_header,
      classroom_header,
      class_header,
      conteudo_header
    ]

    discipline_cells = []

    @discipline_lesson_plans.each do |discipline_lesson_plan|

      classes = (!discipline_lesson_plan.classes ? '' : discipline_lesson_plan.classes.map { |classes| classes}.join(", "))

      discipline_cell = make_cell(content: discipline_lesson_plan.discipline.description, size: 8, align: :left)
      plan_date_cell = make_cell(content: discipline_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 8, align: :left)
      classroom_cell = make_cell(content: discipline_lesson_plan.lesson_plan.classroom.description, size: 8, align: :left)
      class_cell = make_cell(content: classes.to_s, size: 8, align: :left)
      conteudo_cell = make_cell(content: discipline_lesson_plan.lesson_plan.contents, size: 8, align: :left)

      discipline_cells << [
        discipline_cell, 
        plan_date_cell, 
        classroom_cell, 
        class_cell, 
        conteudo_cell
      ]

    end

    data = [headers]
    data.concat(discipline_cells)

    bounding_box([0, 727], width: bounds.width) do
      table(data, row_colors: ['DEDEDE', 'FFFFFF'], width: bounds.width, header: true) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
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