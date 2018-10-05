require 'rails_helper'

RSpec.describe AbsenceAdjustmentsService, type: :service do
  let!(:year) { Time.zone.today.year }
  let!(:unities) { create_list(:unity, 2) }
  let!(:teacher) { create(:teacher) }

  subject do
    AbsenceAdjustmentsService.new(unities, year)
  end

  describe '#adjust' do
    context 'when exists absence by discipline and should be general absence' do
      let!(:classroom) { create(:classroom, :current) }
      let!(:discipline) { create(:discipline) }
      let!(:daily_frequency_1) do
        create(
          :daily_frequency,
          :current, unity: unities.first,
          classroom: classroom,
          discipline: discipline
        )
      end
      let!(:daily_frequency_2) do
        create(
          :daily_frequency,
          :current,
          unity: unities.first,
          classroom: classroom,
          discipline: discipline,
          class_number: 2
        )
      end
      let!(:teacher_discipline_classroom_1) do
        create(
          :teacher_discipline_classroom,
          :current, classroom: classroom,
          discipline: discipline,
          teacher: teacher
        )
      end

      it 'needs to adjust to be general absence' do
        expect(daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be true
        subject.adjust
        expect(daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be false
      end

      it 'removes others daily_frequencies' do
        expect(DailyFrequency.count).to be(2)
        subject.adjust
        expect(DailyFrequency.count).to be(1)
      end
    end

    context 'when exists general absence and should be absence by discipline' do
      let!(:classroom) { create(:classroom, :by_discipline) }
      let!(:school_calendar) { create(:school_calendar_with_one_step, :current) }
      let!(:daily_frequency_1) do
        create(
          :daily_frequency,
          :current,
          :without_discipline,
          unity: unities.first,
          classroom: classroom,
          school_calendar: school_calendar
        )
      end
      let!(:daily_frequency_2) do
        create(
          :daily_frequency,
          :without_discipline,
          unity: unities.first,
          classroom: classroom,
          school_calendar: school_calendar,
          frequency_date: daily_frequency_1.frequency_date.prev_day
        )
      end
      let!(:user) { create(:user, teacher: teacher) }
      let!(:teacher_discipline_classroom_by_discipline) do
        create(
          :teacher_discipline_classroom,
          :current,
          classroom: classroom,
          teacher: teacher
        )
      end

      it 'needs to adjust to be absence by discipline' do
        add_user_to_audit(daily_frequency_1)
        add_user_to_audit(daily_frequency_2)

        expect(daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be true
        subject.adjust
        expect(daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be false
      end
    end
  end

  private

  def daily_frequencies_by_type(frequency_type)
    daily_frequencies = DailyFrequency.joins(:classroom)
                                      .merge(Classroom.joins(:exam_rule).where(exam_rules: { frequency_type: frequency_type }))
                                      .where('extract(year from frequency_date) = ?', year)
                                      .where(unity_id: unities)

    daily_frequencies = daily_frequencies.where.not(discipline_id: nil) if frequency_type == FrequencyTypes::GENERAL
    daily_frequencies = daily_frequencies.where(discipline_id: nil) if frequency_type == FrequencyTypes::BY_DISCIPLINE

    daily_frequencies
  end

  def add_user_to_audit(daily_frequency)
    audit = Audited::Adapters::ActiveRecord::Audit.where(auditable_type: 'DailyFrequency',
                                                         auditable_id: daily_frequency.id).first
    audit.update_column(:user_id, user.id)
  end
end
