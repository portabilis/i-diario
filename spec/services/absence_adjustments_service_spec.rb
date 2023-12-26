require 'rails_helper'

RSpec.describe AbsenceAdjustmentsService, type: :service do
  let!(:year) { Date.current.year }
  let!(:unities) { create_list(:unity, 2) }
  let!(:teacher) { create(:teacher) }

  subject do
    AbsenceAdjustmentsService.new(unities, year)
  end

  describe '#adjust' do
    context 'when exists absence by discipline and should be general absence' do
      let!(:discipline) { create(:discipline) }
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom,
          :score_type_numeric,
          teacher: teacher,
          discipline: discipline,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          discipline: discipline,
          class_number: 1
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :by_discipline,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          discipline: discipline,
          class_number: 2
        )
      }

      it 'needs to adjust to be general absence' do
        expect(subject.daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be true
        FrequencyTypeDefiner.any_instance.stub(:define_frequency_type).and_return(FrequencyTypes::GENERAL)
        subject.adjust
        expect(subject.daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be false
      end

      it 'removes others daily_frequencies' do
        FrequencyTypeDefiner.any_instance.stub(:define_frequency_type).and_return(FrequencyTypes::GENERAL)
        expect(DailyFrequency.count).to be(2)
        subject.adjust
        expect(DailyFrequency.count).to be(0)
      end
    end

    context 'when exists general absence and should be absence by discipline' do
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom,
          :by_discipline_create_rule,
          teacher: teacher,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          :without_discipline,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :without_discipline,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          frequency_date: daily_frequency_1.frequency_date.prev_day
        )
      }
      let!(:user) { create(:user, teacher: teacher) }

      it 'needs to adjust to be absence by discipline' do
        add_user_to_audit(daily_frequency_1)
        add_user_to_audit(daily_frequency_2)

        expect(subject.daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be true
        subject.adjust
        expect(subject.daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be false
      end
    end

    context 'when exists general absence should be absence by discipline because teacher is for a specific area' do
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom_specific,
          :score_type_numeric,
          teacher: teacher,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          :without_discipline,
          :with_teacher,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          teacher: teacher,
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :without_discipline,
          :with_teacher,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          teacher: teacher,
          frequency_date: daily_frequency_1.frequency_date.prev_day
        )
      }
      let!(:user) { create(:user, teacher: teacher) }

      it 'needs to adjust to be absence by discipline when teacher is for a specific area' do
        expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be true
        subject.adjust
        expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be false
      end
    end
  end

  def add_user_to_audit(daily_frequency)
    audit = Audited::Audit.where(
      auditable_type: 'DailyFrequency',
      auditable_id: daily_frequency.id
    ).first
    audit.update(user_id: user.id)
  end
end
