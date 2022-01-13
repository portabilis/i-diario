require 'rails_helper'

RSpec.describe SchoolCalendar, type: :model do
  describe 'attributes' do
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:number_of_classes) }
    it { expect(subject).to respond_to(:unity_id) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to have_many(:steps) }
    it { expect(subject).to have_many(:events) }
  end

  describe 'scopes' do
    describe '.by_school_day' do
      it 'should return the school calendars where the date informed is a valid school day' do
        school_calendar_one = build(:school_calendar, year: 2020)
        school_calendar_one.steps.build(
          start_at: '2020-02-15',
          end_at: '2020-05-01',
          start_date_for_posting: '2020-02-15',
          end_date_for_posting: '2020-05-01'
        )
        school_calendar_one.save!

        school_calendar_two = build(:school_calendar, year: 2021)
        school_calendar_two.steps.build(
          start_at: '2021-02-15',
          end_at: '2021-05-01',
          start_date_for_posting: '2021-02-15',
          end_date_for_posting: '2021-05-01'
        )
        school_calendar_two.save!

        school_calendar_three = build(:school_calendar, year: 2022)
        school_calendar_three.steps.build(
          start_at: '2022-02-15',
          end_at: '2022-05-01',
          start_date_for_posting: '2022-02-15',
          end_date_for_posting: '2022-05-01'
        )
        school_calendar_three.save!

        relation = SchoolCalendar.by_school_day('15/03/2021')

        expect(relation.exists?(school_calendar_one.id)).to be(false)
        expect(relation.exists?(school_calendar_two.id)).to be(true)
        expect(relation.exists?(school_calendar_three.id)).to be(false)
      end
    end
  end

  describe '#school_day?' do
    before do
      @school_calendar = build(:school_calendar, year: 2020, number_of_classes: 5)
      @school_calendar.steps.build(start_at: '2020-02-15',
                                   end_at: '2020-05-01',
                                   start_date_for_posting: '2020-02-15',
                                   end_date_for_posting: '2020-05-01')
      @school_calendar.save!
      @school_calendar.events.create(start_date: '2020-04-25', end_date: '2020-04-25', description: 'Dia extra letivo', event_type: EventTypes::EXTRA_SCHOOL)
    end

    context 'when the date is school day with a holiday event' do
      it 'returns false' do
        date = '2020-04-21'.to_date
        expect(@school_calendar.school_day?(date)).to eq(false)
      end
    end

    context 'when the date is a weekend day' do
      it 'returns false' do
        date = '2020-05-03'.to_date
        expect(@school_calendar.school_day?(date)).to eq(false)
      end
    end

    context 'when the date is a weekend day with extra school event' do
      it 'returns true' do
        date = '2020-04-25'.to_date
        expect(@school_calendar.school_day?(date)).to eq(true)
      end
    end

    context 'when the date is school day without a holiday event' do
      it 'returns true' do
        date = '2020-04-20'.to_date
        expect(@school_calendar.school_day?(date)).to eq(true)
      end
    end
  end
end
