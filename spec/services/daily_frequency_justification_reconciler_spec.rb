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

  def stub_justified_on_date(student_id_to_class_map)
    allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
      student_id_to_class_map.transform_values { |class_map| { daily_frequency.frequency_date => class_map } }
    )
  end

  describe '.call' do
    context 'when the justification is on a class_number that does not match the frequency' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: absence_justifications_student.id
        )
      end

      before do
        # Justificativa lançada na aula 3, mas a frequência agora é aula 1 -> não casa
        stub_justified_on_date(student.id => { 3 => absence_justifications_student.id })
      end

      it 'removes the stale absence justification tag' do
        described_class.call(daily_frequency)

        expect(daily_frequency_student.reload.absence_justification_student_id).to be_nil
      end

      it 'does not reactivate present when removing the tag' do
        described_class.call(daily_frequency)

        # present autoritativo: remover o vínculo não volta o aluno para presente
        expect(daily_frequency_student.reload.present).to eq(false)
      end
    end

    context 'when the justification matches the frequency class_number' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: true,
          absence_justification_student_id: nil
        )
      end

      before do
        stub_justified_on_date(student.id => { 1 => absence_justifications_student.id })
      end

      it 'links the absence justification tag and marks the student as absent' do
        described_class.call(daily_frequency)

        daily_frequency_student.reload
        expect(daily_frequency_student.absence_justification_student_id).to eq(absence_justifications_student.id)
        expect(daily_frequency_student.present).to eq(false)
      end
    end

    context 'when there is a general justification (class_number zero)' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: true,
          absence_justification_student_id: nil
        )
      end

      before do
        # Justificativa geral (aula 0) casa com qualquer aula da frequência
        stub_justified_on_date(student.id => { 0 => absence_justifications_student.id })
      end

      it 'links the general justification to the frequency' do
        described_class.call(daily_frequency)

        expect(daily_frequency_student.reload.absence_justification_student_id).to eq(absence_justifications_student.id)
      end
    end

    context 'when there is both a general and a specific justification on the same date' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let(:general_justification) { create(:absence_justifications_student) }
      let(:specific_justification) { create(:absence_justifications_student) }
      let!(:daily_frequency_student) do
        create_daily_frequency_student(
          daily_frequency: daily_frequency,
          present: false,
          absence_justification_student_id: nil
        )
      end

      before do
        stub_justified_on_date(student.id => { 0 => general_justification.id, 1 => specific_justification.id })
      end

      it 'links the general justification (same precedence as the diary view)' do
        described_class.call(daily_frequency)

        expect(daily_frequency_student.reload.absence_justification_student_id).to eq(general_justification.id)
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

      before do
        stub_justified_on_date(student.id => { 1 => absence_justifications_student.id })
      end

      it 'does not touch the student record' do
        expect { described_class.call(daily_frequency) }
          .not_to(change { daily_frequency_student.reload.updated_at })
      end
    end

    context 'with multiple students in a single call' do
      let(:daily_frequency) { create(:daily_frequency, class_number: 1) }
      let(:student_to_link) { create(:student) }
      let(:student_to_remove) { create(:student) }
      let(:student_already_ok) { create(:student) }
      let(:justification_to_link) { create(:absence_justifications_student) }
      let(:justification_already_ok) { create(:absence_justifications_student) }
      let(:stale_justification) { create(:absence_justifications_student) }

      let!(:row_to_link) do
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student_to_link,
                                         present: true, type_of_teaching: TypesOfTeaching::PRESENTIAL,
                                         absence_justification_student_id: nil)
      end
      let!(:row_to_remove) do
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student_to_remove,
                                         present: false, type_of_teaching: TypesOfTeaching::PRESENTIAL,
                                         absence_justification_student_id: stale_justification.id)
      end
      let!(:row_already_ok) do
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student_already_ok,
                                         present: false, type_of_teaching: TypesOfTeaching::PRESENTIAL,
                                         absence_justification_student_id: justification_already_ok.id)
      end

      before do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_to_link.id => { daily_frequency.frequency_date => { 1 => justification_to_link.id } },
          student_already_ok.id => { daily_frequency.frequency_date => { 1 => justification_already_ok.id } }
          # student_to_remove ausente -> o vínculo obsoleta deve ser removida
        )
      end

      it 'links, removes and keeps each student according to the current class_number' do
        described_class.call(daily_frequency)

        expect(row_to_link.reload.absence_justification_student_id).to eq(justification_to_link.id)
        expect(row_to_remove.reload.absence_justification_student_id).to be_nil
        expect(row_already_ok.reload.absence_justification_student_id).to eq(justification_already_ok.id)
      end
    end

    context 'caching across frequencies of the same classroom, date and period' do
      let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
      let(:frequency_date) { Date.current }
      let(:daily_frequency_1) do
        create(:daily_frequency, classroom: classroom, frequency_date: frequency_date, period: Periods::MATUTINAL, class_number: 1)
      end
      let(:daily_frequency_2) do
        create(:daily_frequency, classroom: classroom, frequency_date: frequency_date, period: Periods::MATUTINAL, class_number: 2)
      end

      before do
        create(:daily_frequency_student, daily_frequency: daily_frequency_1, student: student,
                                         present: false, type_of_teaching: TypesOfTeaching::PRESENTIAL)
        create(:daily_frequency_student, daily_frequency: daily_frequency_2, student: student,
                                         present: false, type_of_teaching: TypesOfTeaching::PRESENTIAL)
      end

      it 'queries the justifications only once for the same classroom, date and period' do
        expect(AbsenceJustifiedOnDate).to receive(:call).once.and_return({})

        cache = {}
        described_class.call(daily_frequency_1, cache)
        described_class.call(daily_frequency_2, cache)
      end
    end
  end
end
