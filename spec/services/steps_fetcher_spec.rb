require 'rails_helper'

RSpec.describe StepsFetcher, type: :service do
  let!(:unity) { create(:unity) }
  let!(:classroom) { create(:classroom, :score_type_numeric_and_concept, unity: unity) }
  let!(:school_calendar) {
    create(
      :school_calendar,
      :with_trimester_steps,
      unity: unity
    )
  }

  subject { StepsFetcher.new(classroom) }

  context 'when there is only the steps of the school calendar' do
    let(:step) { school_calendar.steps.last }

    describe '#steps' do
      it 'returns the steps of the school calendar according to the classroom' do
        expect(subject.steps).to eq(school_calendar.steps)
      end
    end

    describe '#step' do
      context 'when there is step of the school calendar on date' do
        it 'returns the step' do
          expect(subject.step(step.step_number)).to eq(step)
        end
      end

      context 'when there is no step of the school calendar on date' do
        it 'returns nil' do
          expect(subject.step(step.step_number + 1)).to eq(nil)
        end
      end
    end

    describe '#current_step' do
      context 'when there is step of the school calendar on the current date' do
        it 'returns the step' do
          step = school_calendar.step(Date.current)

          expect(subject.current_step).to eq(step)
        end
      end

      context 'when there is no step of the school calendar on the current date' do
        it 'returns nil' do
          Timecop.freeze(Date.current.year, step.start_at.month, 1, 0, 0, 0) do
            expect(subject.current_step).to eq(nil)
          end
        end
      end
    end

    describe '#step_belongs_to_date?' do
      context 'when the step of the school calendar is on date' do
        it 'returns true' do
          expect(subject.step_belongs_to_date?(step.id, step.start_at)).to eq(true)
        end
      end

      context 'when the step of the school calendar is not on date' do
        it 'returns false' do
          expect(subject.step_belongs_to_date?(step.id, step.start_at.beginning_of_month)).to eq(false)
        end
      end
    end
  end

  context 'when there is the steps of the classroom' do
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
      it 'returns the steps of the classroom according to the classroom' do
        expect(subject.steps).to eq(school_calendar_classroom.classroom_steps)
      end
    end

    describe '#step' do
      context 'when there is step of the classroom on date' do
        it 'returns the step of the classroom' do
          expect(subject.step(step.step_number)).to eq(step)
        end
      end

      context 'when there is no step of the classroom on date' do
        it 'returns nil' do
          expect(subject.step(step.step_number + 1)).to eq(nil)
        end
      end
    end

    describe '#current_step' do
      context 'when there is step of the classroom on the current date' do
        it 'returns the step of the classroom' do
          step = school_calendar_classroom.classroom_step(Date.current)

          expect(subject.current_step).to eq(step)
        end
      end

      context 'when there is no step of the classroom on the current date' do
        it 'returns nil' do
          Timecop.freeze(Date.current.year, step.start_at.month, 1, 0, 0, 0) do
            expect(subject.current_step).to eq(nil)
          end
        end
      end
    end

    describe '#step_belongs_to_date?' do
      context 'when the step of the classroom is on date' do
        it 'returns true' do
          expect(subject.step_belongs_to_date?(step.id, step.start_at)).to eq(true)
        end
      end

      context 'when the step of the classroom is not on date' do
        it 'returns false' do
          expect(subject.step_belongs_to_date?(step.id, step.start_at.beginning_of_month)).to eq(false)
        end
      end
    end
  end
end
