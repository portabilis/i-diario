require 'spec_helper'

RSpec.describe TransferNotesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  # Valida a nota de transferência e as notas do aluno antes de persistir: nota acima do
  # máximo ou nenhuma nota informada não salvam nada; notas válidas salvam tudo.
  describe '#save_transfer_note_with_students' do
    # test_setting padrão é aritmético com maximum_score 10 => nota máxima permitida 10.0
    let(:daily_note) { create(:daily_note) }
    let(:student) { create(:student) }
    let(:transfer_note) { build(:transfer_note, :with_teacher_discipline_classroom) }

    def build_student(note)
      DailyNoteStudent.new(daily_note: daily_note, student: student, active: true, note: note)
    end

    before do
      # a factory adiciona uma nota automaticamente; limpa para isolar o cenário do teste
      transfer_note.daily_note_students = []
      controller.instance_variable_set(:@transfer_note, transfer_note)
    end

    context 'when a note exceeds the avaliation maximum score' do
      before do
        controller.instance_variable_set(:@students_ordered, [build_student(11)])
      end

      it 'returns false and does not persist the transfer note (avoids orphan record)' do
        result = nil
        expect { result = controller.send(:save_transfer_note_with_students) }.to_not change(TransferNote, :count)

        expect(result).to eq(false)
        expect(transfer_note).to_not be_persisted
      end

      it 'does not persist the student note' do
        expect { controller.send(:save_transfer_note_with_students) }.to_not change(DailyNoteStudent, :count)
      end

      it 'adds a numericality error on the invalid note input' do
        controller.send(:save_transfer_note_with_students)

        invalid_student = controller.instance_variable_get(:@students_ordered).first

        expect(invalid_student.errors.details[:note]).to include(
          a_hash_including(error: :less_than_or_equal_to)
        )
      end
    end

    context 'when no note is informed' do
      before do
        controller.instance_variable_set(:@students_ordered, [build_student(nil)])
      end

      it 'returns false and does not persist the transfer note' do
        result = nil
        expect { result = controller.send(:save_transfer_note_with_students) }.to_not change(TransferNote, :count)

        expect(result).to eq(false)
      end

      it 'adds an at_least_one_note_required error on base' do
        controller.send(:save_transfer_note_with_students)

        expect(transfer_note.errors.details[:base]).to include(
          a_hash_including(error: :at_least_one_note_required)
        )
      end
    end

    context 'when all notes are within the maximum score' do
      before do
        controller.instance_variable_set(:@students_ordered, [build_student(8)])
      end

      it 'returns true and persists the transfer note with the student notes' do
        expect(controller.send(:save_transfer_note_with_students)).to eq(true)

        student_note = controller.instance_variable_get(:@students_ordered).first

        expect(transfer_note).to be_persisted
        expect(student_note).to be_persisted
        expect(student_note.transfer_note_id).to eq(transfer_note.id)
      end
    end
  end

  # Verificação em tempo real usada na tela de novo lançamento para avisar (e linkar para a
  # edição) quando o aluno já possui uma nota de transferência para a mesma turma,
  # disciplina e etapa.
  describe '#existing_transfer_note' do
    let(:user) { create(:user, :with_user_role_administrator) }
    let!(:transfer_note) { create(:transfer_note, :with_teacher_discipline_classroom) }

    before do
      sign_in(user)
      allow(controller).to receive(:require_current_classroom).and_return(true)
      allow(controller).to receive(:require_current_teacher).and_return(true)
    end

    def existing_request(student_id)
      get :existing_transfer_note, params: {
        locale: 'pt-BR',
        classroom_id: transfer_note.classroom_id,
        discipline_id: transfer_note.discipline_id,
        step_id: transfer_note.step_id,
        student_id: student_id,
        format: :json
      }

      JSON.parse(response.body)
    end

    it 'returns exists true with the existing record id when the student already has one' do
      body = existing_request(transfer_note.student_id)

      expect(body['exists']).to eq(true)
      expect(body['id']).to eq(transfer_note.id)
    end

    it 'returns exists false for a student without a transfer note in the scope' do
      other_student = create(:student)

      body = existing_request(other_student.id)

      expect(body['exists']).to eq(false)
    end
  end

  describe '#build_daily_note_students' do
    let(:daily_note) { create(:daily_note) }
    let(:student) { create(:student) }

    before do
      controller.instance_variable_set(:@transfer_note, build(:transfer_note, :with_teacher_discipline_classroom))
    end

    def attributes_for_note(note)
      ActionController::Parameters.new(
        '0' => {
          daily_note_id: daily_note.id.to_s,
          student_id: student.id.to_s,
          note: note,
          active: 'true'
        }
      ).permit!
    end

    it 'parses the localized note (comma decimal) and sets @students_ordered' do
      controller.send(:build_daily_note_students, attributes_for_note('8,00'))

      students = controller.instance_variable_get(:@students_ordered)

      expect(students.length).to eq(1)
      expect(students.first.attributes['note'].to_f).to eq(8.0)
    end

    it 'reuses an existing DailyNoteStudent for the same daily_note and student' do
      existing = create(:daily_note_student, daily_note: daily_note, student: student, note: 3)

      controller.send(:build_daily_note_students, attributes_for_note('9,00'))

      students = controller.instance_variable_get(:@students_ordered)

      expect(students.map(&:id)).to eq([existing.id])
      expect(students.first.attributes['note'].to_f).to eq(9.0)
    end
  end
end
