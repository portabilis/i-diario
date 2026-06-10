require 'rails_helper'

RSpec.describe DailyFrequencyJustificationReconciler, type: :service do
  # O reconciliador realinha a falta justificada (absence_justification_student_id)
  # de cada aluno com o que o Preserver (mesma fonte do diário) calcularia para a aula atual
  # da frequência: vincula quando casa, remove quando não casa.

  let(:student) { create(:student) }
  let(:absence_justifications_student) { create(:absence_justifications_student) }

  def create_daily_frequency_student(daily_frequency:, present:, absence_justification_student_id:)
    create(
      :daily_frequency_student,
      daily_frequency: daily_frequency,
      student: student,
      present: present,
      type_of_teaching: TypesOfTeaching::PRESENTIAL,
      absence_justification_student_id: absence_justification_student_id
    )
  end

  describe '.call' do
    context 'when there is no justification matching the frequency class_number' do
      let(:daily_frequency) { create(:daily_frequency, :without_discipline) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: absence_justifications_student.id
        )
      end

      before do
        allow(AbsenceJustificationPreserver).to receive(:call).and_return({})
      end

      it 'removes the stale absence justification tag' do
        described_class.call(daily_frequency)

        expect(daily_frequency_student.reload.absence_justification_student_id).to be_nil
      end
    end

    context 'when there is a justification matching the frequency class_number' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: true,
          absence_justification_student_id: nil
        )
      end

      before do
        allow(AbsenceJustificationPreserver).to receive(:call).and_return(
          student.id => absence_justifications_student.id
        )
      end

      it 'links the absence justification tag and marks the student as absent' do
        described_class.call(daily_frequency)

        daily_frequency_student.reload
        expect(daily_frequency_student.absence_justification_student_id).to eq(absence_justifications_student.id)
        expect(daily_frequency_student.present).to eq(false)
      end
    end

    context 'when the tag is already consistent' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: absence_justifications_student.id
        )
      end

      it 'does not save the student again' do
        allow(AbsenceJustificationPreserver).to receive(:call).and_return(
          student.id => absence_justifications_student.id
        )

        expect_any_instance_of(DailyFrequencyStudent).not_to receive(:save!)

        described_class.call(daily_frequency)
      end
    end

    context 'class_number sent to the preserver' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 3) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: nil
        )
      end

      it 'looks up justifications using the frequency class_number' do
        expect(AbsenceJustificationPreserver).to receive(:call).with(
          hash_including(class_number: 3)
        ).and_return({})

        described_class.call(daily_frequency)
      end
    end

    context 'when the frequency is general (no class_number)' do
      let(:daily_frequency) { create(:daily_frequency, :without_discipline) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: nil
        )
      end

      it 'looks up justifications using class_number zero' do
        expect(AbsenceJustificationPreserver).to receive(:call).with(
          hash_including(class_number: 0)
        ).and_return({})

        described_class.call(daily_frequency)
      end
    end
  end
end
