require 'rails_helper'

RSpec.describe AbsenceJustificationPreserver, type: :service do
  # Este service tem como objetivo buscar e aplicar justificativas existentes para preservá-las.
  # Exemplo: Professor abre a tela de frequência, secretaria cadastra a justificativa,
  # professor marca o aluno como presente/ausente e salva.
  # Nesse caso, a justificativa da secretária deve ser preservada e o aluno deve ser marcado com FJ

  let(:frequency_date) { Date.current }
  let(:classroom_id) { 123 }
  let(:period) { Periods::MATUTINAL }
  let(:class_number) { 1 }
  let(:student_id_1) { 100 }
  let(:student_id_2) { 200 }
  let(:absence_justification_id_1) { 999 }
  let(:absence_justification_id_2) { 888 }

  describe '.call' do
    let(:frequency_date) { Date.current }
    let(:classroom_id) { 123 }
    let(:period) { Periods::MATUTINAL }
    let(:class_number) { 1 }
    let(:student_id_1) { 100 }
    let(:student_id_2) { 200 }
    let(:absence_justification_id_1) { 999 }
    let(:absence_justification_id_2) { 888 }

    let(:params) do
      {
        frequency_date: frequency_date,
        classroom_id: classroom_id,
        period: period,
        class_number: class_number,
        student_ids: [student_id_1, student_id_2]
      }
    end

    context 'when there are existing absence justifications for specific class_number' do
      it 'returns hash with student_id => justification_id mapping' do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_id_1 => {
            frequency_date => {
              class_number => absence_justification_id_1
            }
          },
          student_id_2 => {
            frequency_date => {
              class_number => absence_justification_id_2
            }
          }
        )

        result = described_class.call(params)

        expect(result).to eq(
          student_id_1 => absence_justification_id_1,
          student_id_2 => absence_justification_id_2
        )
      end
    end

    context 'when there are general absence justifications (class_number 0)' do
      it 'returns justifications for class_number 0 when specific class_number not found' do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_id_1 => {
            frequency_date => {
              0 => absence_justification_id_1
            }
          }
        )

        result = described_class.call(params)

        expect(result).to eq(
          student_id_1 => absence_justification_id_1
        )
      end
    end

    context 'when specific class_number has priority over general (0)' do
      it 'returns the specific class_number justification' do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_id_1 => {
            frequency_date => {
              0 => 777, # Justificativa geral
              class_number => absence_justification_id_1 # Justificativa específica (deve prevalecer)
            }
          }
        )

        result = described_class.call(params)

        expect(result).to eq(
          student_id_1 => absence_justification_id_1
        )
      end
    end

    context 'when there are no absence justifications' do
      it 'returns empty hash' do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return({})

        result = described_class.call(params)

        expect(result).to eq({})
      end
    end

    context 'when some students have justifications and others do not' do
      it 'returns only students with justifications' do
        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_id_1 => {
            frequency_date => {
              class_number => absence_justification_id_1
            }
          },
          student_id_2 => {} # Sem justificativa
        )

        result = described_class.call(params)

        expect(result).to eq(
          student_id_1 => absence_justification_id_1
        )
      end
    end

    context 'when student_ids is empty' do
      it 'returns empty hash without calling AbsenceJustifiedOnDate' do
        params[:student_ids] = []

        expect(AbsenceJustifiedOnDate).not_to receive(:call)

        result = described_class.call(params)

        expect(result).to eq({})
      end
    end

    context 'when student_ids is a single value (not array)' do
      it 'converts to array and processes correctly' do
        params[:student_ids] = student_id_1

        allow(AbsenceJustifiedOnDate).to receive(:call).and_return(
          student_id_1 => {
            frequency_date => {
              class_number => absence_justification_id_1
            }
          }
        )

        result = described_class.call(params)

        expect(result).to eq(
          student_id_1 => absence_justification_id_1
        )
      end
    end

    it 'calls AbsenceJustifiedOnDate with correct parameters' do
      expect(AbsenceJustifiedOnDate).to receive(:call).with(
        students: [student_id_1, student_id_2],
        date: frequency_date,
        end_date: frequency_date,
        classroom: classroom_id,
        period: period
      ).and_return({})

      described_class.call(params)
    end
  end
end
