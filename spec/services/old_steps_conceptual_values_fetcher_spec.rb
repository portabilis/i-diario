require 'rails_helper'

RSpec.describe OldStepsConceptualValuesFetcher, type: :service do
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_trimester_steps
    )
  }
  let(:steps) { classroom.calendar.classroom_steps }
  let(:student) { create(:student) }

  before do
    steps.each do |step|
      exam = build(
        :conceptual_exam,
        :with_one_value,
        classroom: classroom,
        student: student,
        step_id: step.id,
        recorded_at: Date.current,
        step_number: step.step_number
      )
      exam.save(validate: false)
    end
  end

  context 'has 2 steps with conceptual exams posted before current steps' do
    subject do
      described_class.new(classroom, student, steps[2])
    end

    it 'return the two steps' do
      steps = subject.fetch
      expect(steps.count).to eq(2)
      expect(steps.first[:values].count).to be(1)
    end
  end

  context 'has 2 steps with conceptual exams posted after and equal current step' do
    subject do
      described_class.new(classroom, student, steps[0])
    end

    it 'dont return any step' do
      expect(subject.fetch.count).to eq(0)
    end
  end
end
