require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanElaborationDayCheck, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:classroom) { create(:classroom) }
  let(:date) { Date.new(2026, 4, 10) }

  it 'returns nil when the date is blank' do
    expect(described_class.error_for(classroom, nil)).to be_nil
  end

  it 'returns nil when the classroom is blank' do
    expect(described_class.error_for(nil, date)).to be_nil
  end

  it 'returns nil when there is no calendar (does not block)' do
    allow(CurrentSchoolCalendarFetcher).to receive(:new).and_return(double(fetch: nil))

    expect(described_class.error_for(classroom, date)).to be_nil
  end

  context 'with a calendar' do
    let(:calendar) { double('SchoolCalendar') }

    before do
      allow(CurrentSchoolCalendarFetcher).to receive(:new).and_return(double(fetch: calendar))
    end

    it 'returns nil when the date is a school day' do
      allow(calendar).to receive(:day_allows_entry?).and_return(true)

      expect(described_class.error_for(classroom, date)).to be_nil
    end

    it 'reports "not a school day" when a step exists but the day is not allowed' do
      allow(calendar).to receive(:day_allows_entry?).and_return(false)
      allow(calendar).to receive_message_chain(:steps, :posting_date_after_and_before, :first).and_return(double)

      expect(described_class.error_for(classroom, date))
        .to eq(I18n.t('errors.messages.not_school_calendar_day'))
    end

    it 'reports "not between steps" when there is no step for the date' do
      allow(calendar).to receive(:day_allows_entry?).and_return(false)
      allow(calendar).to receive_message_chain(:steps, :posting_date_after_and_before, :first).and_return(nil)

      expect(described_class.error_for(classroom, date))
        .to eq(I18n.t('errors.messages.is_not_between_steps'))
    end
  end

  # Integração de verdade: calendário real da unidade + evento não letivo, exercitando o
  # CurrentSchoolCalendarFetcher e o day_allows_entry? de ponta a ponta (sem stub).
  context 'with a real calendar' do
    let(:classroom) { create(:classroom) }
    let!(:classroom_grade) { create(:classrooms_grade, classroom: classroom) }
    let!(:calendar) { create(:school_calendar, :with_one_step, unity: classroom.unity, year: 2017) }

    it 'reports the error for a day blocked by a non-school event' do
      create(:school_calendar_event, school_calendar: calendar,
                                     start_date: '2017-03-03', end_date: '2017-03-03',
                                     classroom: classroom, course: classroom_grade.grade.course,
                                     grade: classroom_grade.grade, coverage: 'by_classroom',
                                     event_type: EventTypes::NO_SCHOOL)

      expect(described_class.error_for(classroom, '2017-03-03'.to_date))
        .to eq(I18n.t('errors.messages.not_school_calendar_day'))
    end
  end
end
