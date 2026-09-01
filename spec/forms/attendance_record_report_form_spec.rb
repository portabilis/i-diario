require 'rails_helper'

RSpec.describe AttendanceRecordReportForm, type: :form do
  # Segunda e terça da semana anterior: dias letivos já passados e dentro da mesma etapa do calendário
  let(:first_date) { Date.current.beginning_of_week - 1.week }
  let(:second_date) { first_date + 1.day }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:school_calendar) { classroom.calendar.school_calendar }
  let(:discipline) { create(:discipline) }

  let(:daily_frequencies) {
    [
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        frequency_date: first_date,
        class_number: 1,
        period: Periods::MATUTINAL
      )
    ]
  }

  let(:no_school_event) {
    {
      date: first_date,
      legend: 'E',
      description: 'Feriado',
      type: EventTypes::NO_SCHOOL,
      coverage: 'by_classroom'
    }
  }
  let(:school_event) {
    {
      date: first_date,
      legend: 'F',
      description: 'Formação',
      type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
      coverage: 'by_classroom'
    }
  }
  let(:events) { [no_school_event] }

  let(:hide_no_school_events) { false }

  subject(:form) {
    described_class.new(
      unity_id: classroom.unity_id,
      classroom_id: classroom.id,
      discipline_id: discipline.id,
      class_numbers: '1',
      period: Periods::MATUTINAL,
      start_at: first_date.strftime('%d/%m/%Y'),
      end_at: second_date.strftime('%d/%m/%Y'),
      school_calendar_year: school_calendar.year,
      school_calendar: school_calendar
    )
  }

  before do
    general_configuration = GeneralConfiguration.first || GeneralConfiguration.create!
    general_configuration.update!(hide_no_school_events_on_attendance_record_report: hide_no_school_events)

    # A definição do tipo de frequência depende de vínculo de professor, alheio à regra sob teste
    allow(form).to receive(:global_absence?).and_return(false)
    allow(form).to receive(:daily_frequencies).and_return(daily_frequencies)
    allow(form).to receive(:school_calendar_events).and_return(events)
  end

  describe 'no-school days validation' do
    context 'when the configuration keeps no-school days visible' do
      it 'accepts a period whose every day is a no-school day' do
        expect(form).to be_valid
      end
    end

    context 'when the configuration hides no-school days' do
      let(:hide_no_school_events) { true }

      it 'rejects a period whose every day is a no-school day' do
        expect(form).not_to be_valid
        expect(form.errors.messages[:daily_frequencies]).to include('Nenhum dia letivo no período informado')
      end

      context 'when a frequency was recorded on a day without a no-school event' do
        let(:daily_frequencies) {
          [
            create(
              :daily_frequency,
              classroom: classroom,
              discipline: discipline,
              frequency_date: first_date,
              class_number: 1,
              period: Periods::MATUTINAL
            ),
            create(
              :daily_frequency,
              classroom: classroom,
              discipline: discipline,
              frequency_date: second_date,
              class_number: 1,
              period: Periods::MATUTINAL
            )
          ]
        }

        it 'accepts the period' do
          expect(form).to be_valid
        end
      end

      context 'when the period also has a school event' do
        let(:events) { [no_school_event, school_event] }

        it 'accepts the period, since the school event still prints a column' do
          expect(form).to be_valid
        end
      end

      context 'when the period has no calendar event at all' do
        let(:events) { [] }

        it 'accepts the period' do
          expect(form).to be_valid
        end
      end
    end
  end
end
