# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyFrequency, :type => :model do
  describe "associations" do
    it { should belong_to :unity }
    it { should belong_to :classroom }
    it { should belong_to :discipline }
    it { should belong_to :school_calendar }
    it { should have_many :students }
  end

  describe "validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :classroom }
    it { should validate_presence_of :frequency_date }
    it { expect(subject).to validate_school_calendar_day_of(:frequency_date) }
    it { should validate_presence_of :school_calendar }
  end

  describe '#destroy' do
    # A turma nasce com duas etapas semestrais; a data congelada cai na segunda, então a janela
    # de lançamento da primeira já venceu e a da segunda está aberta.
    let(:current_date) { Date.new(Date.current.year, 8, 15) }
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:user) { create(:user, admin: false) }
    let!(:daily_frequency) do
      create(
        :daily_frequency,
        :with_students,
        students_count: 2,
        classroom: classroom,
        frequency_date: frequency_date
      )
    end

    around do |example|
      Timecop.freeze(current_date) { example.run }
    end

    before { User.current = user }

    after { User.current = nil }

    context 'when the posting period of the step is open' do
      let(:frequency_date) { current_date }

      it 'destroys the daily frequency and its students' do
        expect {
          expect(daily_frequency.destroy).to eq(daily_frequency)
        }.to change(DailyFrequency, :count).by(-1)

        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(0)
      end
    end

    context 'when the posting period of the step is over' do
      let(:frequency_date) { Date.new(current_date.year, 5, 15) }

      it 'keeps the daily frequency and its students' do
        expect {
          expect(daily_frequency.destroy).to eq(false)
        }.to_not change(DailyFrequency, :count)

        expect(DailyFrequency.exists?(daily_frequency.id)).to eq(true)
        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(2)
      end
    end

    context 'when the date does not belong to any step' do
      let(:frequency_date) { current_date }

      it 'keeps the daily frequency and its students' do
        allow_any_instance_of(StepsFetcher).to receive(:step_by_date).and_return(nil)

        expect {
          expect(daily_frequency.destroy).to eq(false)
        }.to_not change(DailyFrequency, :count)

        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(2)
      end
    end

    context 'when there is no current user' do
      let(:frequency_date) { Date.new(current_date.year, 5, 15) }

      it 'destroys the daily frequency and its students' do
        User.current = nil

        expect {
          expect(daily_frequency.destroy).to eq(daily_frequency)
        }.to change(DailyFrequency, :count).by(-1)

        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(0)
      end
    end

    context 'when the current user is an admin' do
      let(:user) { create(:user, admin: true) }
      let(:frequency_date) { Date.new(current_date.year, 5, 15) }

      it 'destroys the daily frequency and its students' do
        expect {
          expect(daily_frequency.destroy).to eq(daily_frequency)
        }.to change(DailyFrequency, :count).by(-1)

        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(0)
      end
    end

    context 'when the frequency is a general one' do
      let(:frequency_date) { Date.new(current_date.year, 5, 15) }
      let!(:daily_frequency) do
        create(
          :daily_frequency,
          :without_discipline,
          :with_students,
          students_count: 2,
          classroom: classroom,
          frequency_date: frequency_date
        )
      end

      it 'keeps the daily frequency and its students' do
        expect {
          expect(daily_frequency.destroy).to eq(false)
        }.to_not change(DailyFrequency, :count)

        expect(DailyFrequencyStudent.with_discarded.by_daily_frequency_id(daily_frequency.id).count).to eq(2)
      end
    end
  end
end
