# encoding: utf-8

require "prawn/measurement_extensions"

class Attendance
  include Prawn::View

  def self.build(daily_frequencies)
    new.build(daily_frequencies)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :landscape,
                                    margin: [0.5.cm, 0.5.cm, 0.5.cm, 0.5.cm])
  end

  def build(daily_frequencies)
    # daily_frequencies = { 1 => { frequency_date: '24/07/2015', class_number: 1, daily_frequency_students: { 1 => { student_name: 'Aluno 01', present: true },
    #                                                                                                         2 => { student_name: 'Aluno 02', present: true },
    #                                                                                                         3 => { student_name: 'Aluno 03', present: true } } },
    #                       2 => { frequency_date: '24/07/2015', class_number: 2, daily_frequency_students: { 1 => { student_name: 'Aluno 01', present: true },
    #                                                                                                         2 => { student_name: 'Aluno 02', present: true },
    #                                                                                                         3 => { student_name: 'Aluno 03', present: true } } } }

    class_numbers = []
    days = []
    months = []
    students = {}
    daily_frequencies.each do |daily_frequency|
      class_numbers << daily_frequency.class_number
      days << daily_frequency.frequency_date.day
      months << daily_frequency.frequency_date.month
      daily_frequency.students.each do |student|
        (students[student.student.id] ||= {})[:name] = student.student.name
        (students[student.student.id][:attendances] ||= []) << (student.present ? '.' : 'F')
      end
    end

    table([
      [{ content: "Prefeitura Municipal de Içara\nSecretaria de Educação\nEscola Municipal de Içara\nRegistro de Frequência", rowspan: 2 }, "Curso:\nEnsino Fundamental", "Turno:\nMatutino", "Série:\n6º Ano", "Turma: 601"],
      ["Disciplina:\nMatemática", { content: "Professor:\nBruce Wayne", colspan: 3 }]
    ])

    sequential_number_header_cell = make_cell(content: 'Nº', font_style: :bold, align: :center, valign: :center, rowspan: 3)
    student_name_header_cell = make_cell(content: 'Nome do Aluno', font_style: :bold, align: :center, valign: :center, rowspan: 3)
    class_number_header_cell = make_cell(content: 'Aula', font_style: :bold, align: :center)
    day_header_cell = make_cell(content: 'Dia', font_style: :bold, align: :center)
    month_header_cell = make_cell(content: 'Mês', font_style: :bold, align: :center)
    absences_header_cell = make_cell(content: 'Faltas', font_style: :bold, align: :center, valign: :center, rowspan: 3)

    first_headers_and_class_numbers_cells = [sequential_number_header_cell, student_name_header_cell, class_number_header_cell].concat(class_numbers).concat(['01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', '01', '02', absences_header_cell])
    days_header_and_cells = [day_header_cell].concat(days).concat(['03', '03', '04', '04', '05', '05', '06', '06', '07', '07', '08', '08', '09', '09', '10', '10', '11', '11', '12', '12', '13', '13', '14', '14', '15', '15', '16', '16', '17', '17', '18', '18', '19', '19', '20', '20', '21', '21'])
    months_header_and_cells = [month_header_cell].concat(months).concat(['10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10'])

    students_cells = []
    students.each_with_index do |(key, value), index|
      students_cells << [index + 1, { content: value[:name], colspan: 2 }].concat(value[:attendances]).concat([".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", 0])
    end


    data = [
      first_headers_and_class_numbers_cells,
      days_header_and_cells,
      months_header_and_cells
    ]
    data.concat(students_cells)

    table(data, cell_style: { size: 8, padding: [1.6, 1.6, 1.6, 1.6] }, column_widths: { 1 => 140 }, width: 813.5)

    self
  end
end