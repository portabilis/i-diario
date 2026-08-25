require 'rails_helper'

RSpec.describe AttendanceRecordReport, type: :report do
  it 'should be created' do
    skip 'needs to be refactored'
    entity_configuration = create(:entity_configuration)
    classroom = create(:classroom, :with_classroom_semester_steps)
    school_calendar = classroom.calendar.school_calendar

    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar
    )
    create(:student)
    teacher = create(:teacher)

    daily_frequencies = DailyFrequency.all
    students = Student.all

    subject = AttendanceRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      '01/01/2016',
      '01/01/2016',
      daily_frequencies,
      students,
      school_calendar.events.by_date_between('01/01/2016', '01/01/2016').extra_school_without_frequency,
      school_calendar,
      false,
      {}
    ).render

    expect(subject).to be_truthy
  end

  describe 'columns order' do
    # Segunda-feira da semana corrente: dia letivo dentro da etapa do calendário
    let(:frequency_date) { Date.current.beginning_of_week }
    let(:entity_configuration) { create(:entity_configuration) }
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
    let(:school_calendar) { classroom.calendar.school_calendar }
    let(:discipline) { create(:discipline) }
    let(:teacher) { create(:teacher) }
    let(:student) { create(:student) }
    let(:student_enrollment) { create(:student_enrollment, student: student) }
    let(:student_enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade
      )
    }
    let(:enrollment_classrooms_list) {
      [
        {
          student_enrollment: student_enrollment,
          student_enrollment_classroom: student_enrollment_classroom,
          student: student
        }
      ]
    }
    let(:current_user) { double(:current_user, current_role_is_admin_or_employee?: false) }
    let(:events) { [] }
    # Aulas do mesmo dia lançadas fora de ordem numérica
    let(:daily_frequencies) { [7, 9, 1, 3].map { |class_number| create_daily_frequency(class_number) } }

    before do
      # O marcador de presença vem do dicionário de termos da entidade corrente, que não existe fora da requisição
      allow(TermsDictionary).to receive(:cached_current).and_return(
        TermsDictionary.new(presence_identifier_character: '.')
      )
      general_configuration.update!(
        show_percentage_on_attendance_record_report: false,
        show_inactive_enrollments: false
      )
    end

    it 'prints the lessons of the same day in ascending order of class number' do
      expect(class_number_cells(render_report)).to eq(%w[1 3 7 9])
    end

    context 'when the day also has a calendar event' do
      let(:events) {
        [
          {
            date: frequency_date,
            legend: 'E',
            description: 'Evento',
            type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
            coverage: 'by_classroom'
          }
        ]
      }

      it 'prints the event after the lessons of the day' do
        # A célula "Aula" do evento sai vazia, então a posição dele só aparece na linha do aluno:
        # as aulas marcam presença e o evento marca a legenda
        expect(student_attendance_cells(render_report, 5)).to eq(['.', '.', '.', '.', 'E'])
      end
    end

    def render_report
      described_class.build(
        entity_configuration,
        teacher,
        school_calendar.year,
        frequency_date.strftime('%d/%m/%Y'),
        frequency_date.strftime('%d/%m/%Y'),
        daily_frequencies,
        enrollment_classrooms_list,
        events,
        school_calendar,
        false,
        {},
        current_user,
        classroom.id
      ).render
    end

    def create_daily_frequency(class_number)
      daily_frequency = create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        frequency_date: frequency_date,
        class_number: class_number,
        period: Periods::MATUTINAL
      )
      create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)

      daily_frequency.reload
    end

    def general_configuration
      GeneralConfiguration.first || GeneralConfiguration.create!
    end

    # Linha de cabeçalho "Aula": as células entre "Aula" e "Faltas" são os números das aulas impressas
    def class_number_cells(rendered_pdf)
      strings = pdf_strings(rendered_pdf)

      strings[(strings.index('Aula') + 1)...strings.index('Faltas')]
    end

    # Linha do aluno: as células logo após o nome são as colunas do dia, na mesma ordem do cabeçalho
    def student_attendance_cells(rendered_pdf, columns_count)
      strings = pdf_strings(rendered_pdf)
      first_column = strings.index(student.to_s) + 1

      strings[first_column, columns_count]
    end

    def pdf_strings(rendered_pdf)
      PDF::Inspector::Text.analyze(rendered_pdf).strings
    end
  end
end
