require 'rails_helper'

RSpec.describe TransferNotesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
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
      allow(controller).to receive(:authorize).and_return(true)
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

    it 'authorizes the request through the transfer_notes policy' do
      expect(controller).to receive(:authorize).with(TransferNote, :index?).and_return(true)

      existing_request(transfer_note.student_id)
    end
  end
end
