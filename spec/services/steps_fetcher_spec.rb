require 'rails_helper'

RSpec.describe StepsFetcher, type: :service do
  let!(:unity) { create(:unity) }
  let!(:classroom) { create(:classroom_numeric_and_concept, unity: unity) }
  let!(:school_calendar) {
    create(
      :school_calendar,
      :school_calendar_with_trimester_steps,
      :current,
      unity: unity
    )
  }

  subject { StepsFetcher.new(classroom) }

  context 'when there is only school_calendar_steps' do
    let(:step) { school_calendar.steps.last }

    describe '#steps' do
      it 'returns school_calendar_steps according to the classroom' do
        expect(subject.steps).to eq(school_calendar.steps)
      end
    end

    describe '#step' do
      it 'returns school_calendar_step according to the date' do
        expect(subject.step(step.start_at)).to eq(step)
      end

      it 'returns nil when there is no school_calendar_step on date' do
        expect(subject.step(step.start_at.beginning_of_month)).to eq(nil)
      end
    end

    describe '#current_step' do
      it 'returns school_calendar_step according to the current date' do
        step = school_calendar.step(Date.today)

        expect(subject.current_step).to eq(step)
      end

      it 'returns nil when there is no school_calendar_step on current date' do
        Timecop.freeze(Date.today.year, step.start_at.month, 1, 0, 0, 0) do
          expect(subject.current_step).to eq(nil)
        end
      end
    end

    describe '#step_belongs_to_date' do
      it 'returns true when the school_calendar_step is on date' do
        expect(subject.step_belongs_to_date(step.id, step.start_at)).to eq(true)
      end

      it 'returns false when the school_calendar_step is not on date' do
        expect(subject.step_belongs_to_date(step.id, step.start_at.beginning_of_month)).to eq(false)
      end
    end
  end

  context 'when there is school_calendar_classroom_steps' do
    let!(:school_calendar_classroom) {
      create(
        :school_calendar_classroom,
        :school_calendar_classroom_with_trimester_steps,
        school_calendar: school_calendar,
        classroom: classroom
      )
    }
    let(:step) { school_calendar_classroom.classroom_steps.last }

    describe '#steps' do
      it 'returns school_calendar_classroom_steps according to the classroom' do
        expect(subject.steps).to eq(school_calendar_classroom.classroom_steps)
      end
    end

    describe '#step' do
      it 'returns school_calendar_classroom_step according to the date' do
        expect(subject.step(step.start_at)).to eq(step)
      end

      it 'returns nil when there is no school_calendar_classroom_step on date' do
        expect(subject.step(step.start_at.beginning_of_month)).to eq(nil)
      end
    end

    describe '#current_step' do
      it 'returns school_calendar_classroom_step according to the current date' do
        step = school_calendar_classroom.classroom_step(Date.today)

        expect(subject.current_step).to eq(step)
      end

      it 'returns nil when there is no school_calendar_classroom_step on current date' do
        Timecop.freeze(Date.today.year, step.start_at.month, 1, 0, 0, 0) do
          expect(subject.current_step).to eq(nil)
        end
      end
    end

    describe '#step_belongs_to_date' do
      it 'returns true when the school_calendar_classroom_step is on date' do
        expect(subject.step_belongs_to_date(step.id, step.start_at)).to eq(true)
      end

      it 'returns false when the school_calendar_classroom_step is not on date' do
        expect(subject.step_belongs_to_date(step.id, step.start_at.beginning_of_month)).to eq(false)
      end
    end
  end
end
