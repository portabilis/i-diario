require "prawn/measurement_extensions"

class AbsenceJustificationReport
  include Prawn::View

  def self.build(entity_configuration, absence_justifications, absence_justification_report_form)
    new.build(entity_configuration, absence_justifications, absence_justification_report_form)
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

  def build(entity_configuration, absence_justifications, absence_justification_report_form)
    @entity_configuration = entity_configuration
    @absence_justifications = absence_justifications
    @absence_justification_report_form = absence_justification_report_form

    header
    body
    footer

    self
  end

  private

  def header
    absences_header = make_cell(
      content: 'Registro de justificativa de faltas',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    begin
      logo_cell = make_cell(
        image: open(@entity_configuration.logo.url),
        fit: [50, 50],
        width: 70,
        rowspan: 4,
        position: :center,
        vposition: :center
      )
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''
    unity_name = @absence_justifications.first.unity ? @absence_justifications.first.unity.name : ''

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n#{unity_name}",
      size: 12,
      leading: 1.5,
      align: :center,
      valign: :center,
      rowspan: 4,
      padding: [6, 0, 8, 0]
    )

    table_data = [
      [absences_header],
      [logo_cell, entity_organ_and_unity_cell]
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

  def identification
    identification_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    unity_header = make_cell(
      content: 'Unidade',
      size: 8,
      font_style: :bold,
      borders: [:left, :right],
      padding: [2, 2, 4, 4],
      colspan: 2
    )
    unity_cell = make_cell(
      content: @absence_justifications.first.unity ? @absence_justifications.first.unity.name : '',
      size: 10,
      borders: [:left, :right, :bottom],
      padding: [0, 2, 4, 4],
      colspan: 2
    )

    discipline_header = make_cell(
      content: 'Disciplina',
      size: 8,
      font_style: :bold,
      borders: [:left, :right],
      padding: [2, 2, 4, 4]
    )

    discipline_cell = make_cell(
      content: @absence_justifications.first.discipline ? @absence_justifications.first.discipline.description : 'Geral',
      size: 10,
      borders: [:left, :right, :bottom],
      padding: [0, 2, 4, 4]
    )

    classroom_header = make_cell(
      content: 'Turma',
      size: 8,
      font_style: :bold,
      borders: [:right],
      padding: [2, 2, 4, 4]
    )

    classroom_cell = make_cell(
      content: @absence_justifications.first.classroom ? @absence_justifications.first.classroom.description : '-',
      size: 10,
      borders: [:right, :bottom],
      padding: [0, 2, 4, 4]
    )

    teacher_header = make_cell(
      content: 'Professor',
      size: 8,
      font_style: :bold,
      borders: [:left, :right],
      padding: [2, 2, 4, 4]
    )

    teacher_cell = make_cell(
      content: @absence_justifications.first.teacher ? @absence_justifications.first.teacher.name : "-",
      size: 10,
      borders: [:left, :right, :bottom],
      padding: [0, 2, 4, 4]
    )

    period_header = make_cell(
      content: 'Período',
      size: 8,
      font_style: :bold,
      borders: [:right],
      padding: [2, 2, 4, 4]
    )

    initial_date = @absence_justification_report_form.absence_date ? @absence_justification_report_form.absence_date : ''
    final_date = @absence_justification_report_form.absence_date_end ? @absence_justification_report_form.absence_date_end : ''

    period_cell = make_cell(
      content: "#{initial_date} a #{final_date}",
      size: 10,
      borders: [:right, :bottom],
      padding: [0, 2, 4, 4]
    )

    identification_table_data = [
      [identification_header_cell],
      [unity_header],
      [unity_cell],
      [discipline_header, classroom_header],
      [discipline_cell, classroom_cell],
      [teacher_header, period_header],
      [teacher_cell, period_cell]
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

    title_general_information = [
      [general_information_header_cell]
    ]

    initial_date_header = make_cell(
      content: 'Data inicial',
      size: 8,
      font_style: :bold,
      width: 65,
      background_color: 'FFFFFF',
      align: :left,
    )

    final_date_header = make_cell(
      content: 'Data final',
      size: 8,
      font_style: :bold,
      width: 65,
      background_color: 'FFFFFF',
      align: :left
    )

    student_header = make_cell(
      content: 'Aluno',
      size: 8,
      font_style: :bold,
      width: 220,
      background_color: 'FFFFFF',
      align: :left
    )

    justification_header = make_cell(
      content: 'Justificativa',
      size: 8,
      font_style: :bold,
      background_color: 'FFFFFF',
      align: :left
    )

    headers = [
      initial_date_header,
      final_date_header,
      student_header,
      justification_header
    ]

    general_information_cells = []
    @absence_justifications.each do |absence_justification|
      initial_date_cell = make_cell(
        content: "#{absence_justification.absence_date.strftime("%d/%m/%Y")}",
        size: 10,
        width: 65,
        align: :left
      )

      final_date_cell = make_cell(
        content: "#{absence_justification.absence_date_end.strftime("%d/%m/%Y")}",
        size: 10,
        width: 65,
        align: :left
      )

      student_cell = make_cell(
        content: absence_justification.student.name,
        size: 10,
        width: 220,
        align: :left
      )

      justification_cell = make_cell(
        content: absence_justification.justification,
        size: 10,
        align: :left
      )

      general_information_cells << [
        initial_date_cell,
        final_date_cell,
        student_cell,
        justification_cell
      ]

    end
    general_information_table_data = [
      headers
    ]

    general_information_table_data.concat(general_information_cells)

    move_down 8

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
    bounding_box([0, 712], width: bounds.width, height: 700) do
      identification
      general_information
      signatures
    end
  end

  def signatures
    start_new_page if cursor < 45

    move_down 30
    text_box("______________________________________________\nProfessor(a)", size: 10, align: :center, at: [0, cursor], width: 260)
    text_box("______________________________________________\nCoordenador(a)", size: 10, align: :center, at: [306, cursor], width: 260)
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
end
