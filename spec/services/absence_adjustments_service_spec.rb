require 'rails_helper'

RSpec.describe AbsenceAdjustmentsService, type: :service do
  let!(:year) { Time.zone.today.year }
  let!(:unities) { create_list(:unity, 2) }
  let(:daily_frequency) { create(:daily_frequency, :current, unity: unities.first) }
  let(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, :current,
           classroom: daily_frequency.classroom,
           discipline: daily_frequency.discipline,
           teacher: teacher)
  end
  let(:classroom) { create(:classroom, :by_discipline) }
  let(:daily_frequency_by_discipline) { create(:daily_frequency, :current, :without_discipline,
                                               unity: unities.first, classroom: classroom) }
  let(:teacher) { create(:teacher) }
  let(:user) { create(:user, teacher: teacher) }
  let(:teacher_discipline_classroom_by_discipline) do
    create(:teacher_discipline_classroom, :current,
            classroom: daily_frequency_by_discipline.classroom,
            teacher: teacher)
  end

  subject do
    AbsenceAdjustmentsService.new(unities, year)
  end

  describe '#adjust' do
    it 'when exists absence by discipline and should be general absence' do
      daily_frequency
      teacher_discipline_classroom
      expect(daily_frequencies.count).to be(1)
      subject.adjust
      expect(daily_frequencies.count).to be(0)
    end

    it 'when exists general absence and should be absence by discipline' do
      daily_frequency_by_discipline
      teacher_discipline_classroom_by_discipline
      add_user_to_audit(daily_frequency_by_discipline)
      expect(daily_frequencies_by_discipline.count).to be(1)
      subject.adjust
      expect(daily_frequencies_by_discipline.count).to be(0)
    end
  end

  private

  def daily_frequencies
    DailyFrequency.joins(:classroom).merge(Classroom.joins(:exam_rule)
      .merge(ExamRule.where(frequency_type: FrequencyTypes::GENERAL)))
      .where('extract(year from frequency_date) = ?', year)
      .where(unity_id: unities)
      .where.not(discipline_id: nil)
  end

  def daily_frequencies_by_discipline
    DailyFrequency.joins(:classroom).merge(Classroom.joins(:exam_rule)
      .merge(ExamRule.where(frequency_type: FrequencyTypes::BY_DISCIPLINE)))
      .where('extract(year from frequency_date) = ?', year)
      .where(unity_id: unities)
      .where(discipline_id: nil)
  end

  def add_user_to_audit(daily_frequency)
    audit = Audited::Adapters::ActiveRecord::Audit.where(auditable_type: 'DailyFrequency',
                                                         auditable_id: daily_frequency.id).first
    audit.update_column(:user_id, user.id)
  end
end
