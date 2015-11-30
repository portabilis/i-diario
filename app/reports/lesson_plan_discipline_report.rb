require "prawn/measurement_extensions"

class LessonPlanDisciplineReport
  include Prawn::View

  def self.build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
    new.build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :portrait,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, date_start, date_end, discipline_lesson_plan, current_teacher)
    @entity_configuration = entity_configuration
    @date_start = date_start
    @date_end = date_end
    @discipline_lesson_plans = discipline_lesson_plan
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
    title =  'Registro de conteúdos por disciplina'

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

    teacher_discipline_classroom = TeacherDisciplineClassroom.where discipline_id: @discipline_lesson_plans.first.discipline.id, classroom_id: @discipline_lesson_plans.first.lesson_plan.classroom.id

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4], colspan: 2)
    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 3)
    @discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4])
    @plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', width: 60, padding: [2, 2, 4, 4])
    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @class_header = make_cell(content: 'Aulas', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @conteudo_header = make_cell(content: 'Conteúdos', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])

    @unity_cell = make_cell(content:  @discipline_lesson_plans.first.lesson_plan.unity.name, borders: [:bottom, :left, :right], size: 10, width: 240, align: :left, colspan: 3)
    @discipline_cell = make_cell(content: @discipline_lesson_plans.first.discipline.description, borders: [:bottom, :left, :right], size: 10, align: :left)
    @classroom_cell = make_cell(content: @discipline_lesson_plans.first.lesson_plan.classroom.description, borders: [:bottom, :left, :right], size: 10, align: :left)
    @teacher_cell = make_cell(content: (teacher_discipline_classroom.first.teacher.name.present? ? teacher_discipline_classroom.first.teacher.name : @current_teacher.name), borders: [:bottom, :left, :right], size: 10, align: :left, colspan: 2)
    @period_cell = make_cell(content: (@date_start == '' || @date_end == '' ? '-' : "#{@date_start} à #{@date_end}"), borders: [:bottom, :left, :right], size: 10, align: :left)
  end

  def identification
    identification_table_data = [
      [@identification_header_cell],
      [@unity_header, @discipline_header],
      [@unity_cell, @discipline_cell],
      [@classroom_header, @teacher_header, @period_header],
      [@classroom_cell, @teacher_cell, @period_cell]
    ]

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
      @class_header,
      @conteudo_header
    ]

    general_information_cells = []

    @discipline_lesson_plans.each do |discipline_lesson_plan|

      classes = (!discipline_lesson_plan.classes ? '' : discipline_lesson_plan.classes.map { |classes| classes}.join(", "))

      plan_date_cell = make_cell(content: discipline_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 10, align: :left)
      class_cell = make_cell(content: classes.to_s, size: 10, width: 70, align: :left)
      conteudo_cell = make_cell(content: discipline_lesson_plan.lesson_plan.contents, size: 10, align: :left)

      general_information_cells << [
        plan_date_cell,
        class_cell,
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
      draw_text("Data e hora: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}", size: 8, at: [0, 0])

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
