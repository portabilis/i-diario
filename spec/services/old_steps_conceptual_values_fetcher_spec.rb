require 'rails_helper'

RSpec.describe OldStepsConceptualValuesFetcher, type: :service do
  let(:classroom) { create(:classroom, :current) }
  let(:school_calendar) { create(:school_calendar, :school_calendar_with_trimester_steps, unity: classroom.unity) }
  let(:student) { create(:student) }

  before do
    school_calendar.steps.each do |step|
      exam = build(
        :conceptual_exam_with_one_value,
        classroom: classroom,
        unity_id: classroom.unity_id,
        student: student,
        school_calendar_step: step,
        recorded_at: 1.business_days.after(step.start_at)
      )
      exam.save(validate: false)
    end
  end

  context 'has 2 steps with conceptual exams posted before current steps' do
    subject do
      described_class.new(classroom, student, school_calendar.steps[2])
    end

    it 'return the two steps' do
      steps = subject.fetch
      expect(steps.count).to eq(2)
      expect(steps.first[:values].count).to be(1)
    end
  end

  context 'has 2 steps with conceptual exams posted after and equal current step' do
    subject do
      described_class.new(classroom, student, school_calendar.steps[0])
    end

    it 'dont return any step' do
      expect(subject.fetch.count).to eq(0)
    end
  end
end
