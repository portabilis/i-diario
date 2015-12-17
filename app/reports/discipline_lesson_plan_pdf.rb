class DisciplineLessonPlanPdf
  include Prawn::View

  def self.build(entity_configuration, discipline_lesson_plan, current_teacher)
    new.build(entity_configuration, discipline_lesson_plan, current_teacher)
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

  def build(entity_configuration, discipline_lesson_plan, current_teacher)
    @entity_configuration = entity_configuration
    @discipline_lesson_plan = discipline_lesson_plan
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
      content: 'Plano de aula',
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


    classes = (!@discipline_lesson_plan.classes ? '' : @discipline_lesson_plan.classes.map { |classes| classes}.join(", "))

    teacher_discipline_classroom = TeacherDisciplineClassroom.where discipline_id: @discipline_lesson_plan.discipline.id, classroom_id: @discipline_lesson_plan.lesson_plan.classroom.id

    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @teacher_cell = make_cell(content: (teacher_discipline_classroom.first.teacher.name.present? ? teacher_discipline_classroom.first.teacher.name : @current_teacher.name), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 6)
    @unity_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.unity.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 6)

    @plan_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @plan_date_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.lesson_plan_date.strftime("%d/%m/%Y"), size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @classroom_cell = make_cell(content: @discipline_lesson_plan.lesson_plan.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @class_header = make_cell(content: 'Aulas', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 2)
    @class_cell = make_cell(content: classes.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 2)

    @discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, borders: [:left, :right, :top], padding: [2, 2, 4, 4], colspan: 4)
    @discipline_cell = make_cell(content: @discipline_lesson_plan.discipline.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], colspan: 4)

    activitie_cell_content = inline_formated_cell_header('Atividades/metodologia') + (@discipline_lesson_plan.lesson_plan.activities.present? ? @discipline_lesson_plan.lesson_plan.activities : '-')
    @activitie_cell = make_cell(content: activitie_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    conteudo_cell_content = inline_formated_cell_header('Conteúdos') + (@discipline_lesson_plan.lesson_plan.contents.present? ? @discipline_lesson_plan.lesson_plan.contents : '-')
    @conteudo_cell = make_cell(content: conteudo_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    objective_cell_content = inline_formated_cell_header('Objetivos') + (@discipline_lesson_plan.lesson_plan.objectives.present? ? @discipline_lesson_plan.lesson_plan.objectives : '-')
    @objective_cell = make_cell(content: objective_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    resource_cell_content = inline_formated_cell_header('Recursos') + (@discipline_lesson_plan.lesson_plan.resources.present? ? @discipline_lesson_plan.lesson_plan.resources : '-')
    @resource_cell = make_cell(content: resource_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    evaluation_cell_content = inline_formated_cell_header('Avaliação') + (@discipline_lesson_plan.lesson_plan.evaluation.present? ? @discipline_lesson_plan.lesson_plan.evaluation : '-')
    @evaluation_cell = make_cell(content: evaluation_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    bibliography_cell_content = inline_formated_cell_header('Referências') + (@discipline_lesson_plan.lesson_plan.bibliography.present? ? @discipline_lesson_plan.lesson_plan.bibliography : '-')
    @bibliography_cell = make_cell(content: bibliography_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)

    opinion_cell_content = inline_formated_cell_header('Parecer') + @discipline_lesson_plan.lesson_plan.opinion.to_s
    @opinion_cell = make_cell(content: opinion_cell_content, size: 10, borders: [:bottom, :left, :right, :top], padding: [0, 2, 4, 4], colspan: 4)
  end

  def general_information
    general_information_table_data = [
      [@general_information_header_cell],
      [@unity_header],
      [@unity_cell],
      [@discipline_header, @classroom_header],
      [@discipline_cell, @classroom_cell],
      [@teacher_header, @plan_date_header, @class_header],
      [@teacher_cell, @plan_date_cell, @class_cell]
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

    if @discipline_lesson_plan.lesson_plan.opinion.present?
      move_down @gap
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
    bounding_box([0, 712], width: bounds.width, height: 700) do
      general_information
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
