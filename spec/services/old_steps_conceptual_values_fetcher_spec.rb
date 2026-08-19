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
  let(:discipline) { create(:discipline) }

  before do
    steps.each do |step|
      exam = build(
        :conceptual_exam,
        :with_one_value,
        classroom: classroom,
        student: student,
        discipline: discipline,
        step_id: step.id,
        recorded_at: Date.current,
        step_number: step.step_number
      )
      exam.conceptual_exam_values.first.value = 7
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
    end

    it 'serializes the values keyed by discipline id' do
      # Sem tabela de arredondamento vinculada, o valor é serializado como está
      expect(subject.fetch.first[:values]).to eq(discipline.id.to_s => '7.0')
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

  context 'when current step is nil' do
    # StepsFetcher#step_by_id devolve nil quando o step_id não existe, não
    # pertence ao calendário da turma (ex: etapa vinda da lista de outra turma)
    # ou quando a turma não possui calendário escolar no ano.
    subject do
      described_class.new(classroom, student, nil)
    end

    it 'returns an empty array without raising' do
      expect(subject.fetch).to eq([])
    end
  end
end
