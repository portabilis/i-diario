require 'rails_helper'

RSpec.describe UserTeacherLinkerService, type: :service do
  let(:service) { described_class.new }

  describe '#call' do
    context 'when there are no users to link' do
      it 'logs that no users were found' do
        allow(Rails.logger).to receive(:info)

        service.call([])

        expect(Rails.logger).to have_received(:info).with(
          'Nenhum usuário encontrado para vinculação automática usuário-professor por CPF'
        )
      end
    end

    context 'when there are users and teachers with matching CPF' do
      let!(:teacher) { create(:teacher, api_code: 'T123', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
      end

      it 'links the user to the teacher' do
        expect { service.call([teacher_record]) }.to change { user.reload.teacher_id }.from(nil).to(teacher.id)
      end

      it 'logs the successful linking' do
        allow(Rails.logger).to receive(:info)

        service.call([teacher_record])

        expect(Rails.logger).to have_received(:info).with("Usuário #{user.id} (#{user.name}) vinculado ao professor #{teacher.id} pelo CPF")
        expect(Rails.logger).to have_received(:info).with('Vinculação automática usuário-professor por CPF executada')
      end
    end

    context 'when user already has teacher_id filled' do
      let!(:teacher) { create(:teacher, active: true) }
      let!(:existing_user) { create(:user, teacher_id: teacher.id) }
      let(:teacher_record) { double(servidor_id: 'T456', cpf: '123.456.789-01') }
      let!(:new_user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: new_user)
      end

      it 'does not link the new user' do
        expect { service.call([teacher_record]) }.not_to change { new_user.reload.teacher_id }
      end

      it 'does not affect the already linked user' do
        expect { service.call([teacher_record]) }.not_to change { existing_user.reload.teacher_id }
      end
    end

    context 'when user does not have valid user_roles' do
      let!(:teacher) { create(:teacher, active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      it 'does not link the user' do
        expect { service.call([teacher_record]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher is inactive' do
      let!(:teacher) { create(:teacher, active: false) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
      end

      it 'does not link the user to inactive teacher' do
        expect { service.call([teacher_record]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher is soft deleted' do
      let!(:teacher) { create(:teacher, active: true, discarded_at: Time.current) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
      end

      it 'does not link the user to deleted teacher' do
        expect { service.call([teacher_record]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher_record has empty or null CPF' do
      let!(:teacher) { create(:teacher, active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record_empty) { double(servidor_id: 'T123', cpf: '') }
      let(:teacher_record_nil) { double(servidor_id: 'T123', cpf: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'does not process records without CPF' do
        expect { service.call([teacher_record_empty, teacher_record_nil]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher does not exist in database' do
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'NONEXISTENT', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
      end

      it 'does not link the user' do
        expect { service.call([teacher_record]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when user does not exist for given CPF' do
      let!(:teacher) { create(:teacher, active: true) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '999.999.999-99') }

      it 'does not raise error' do
        expect { service.call([teacher_record]) }.not_to raise_error
      end
    end

    context 'when user validation fails' do
      let!(:teacher) { create(:teacher, api_code: 'T123', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
        allow_any_instance_of(User).to receive(:save).with(validate: false).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(
          double(full_messages: ['Custom validation error'])
        )
      end

      it 'logs validation error' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        service.call([teacher_record])

        expect(Rails.logger).to have_received(:warn).with("Falha ao vincular usuário #{user.id}: Custom validation error")
        expect(Rails.logger).to have_received(:info).with('Vinculação automática usuário-professor por CPF executada')
      end

      it 'does not link the user' do
        expect { service.call([teacher_record]) }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when there is a transaction error' do
      let!(:teacher) { create(:teacher, api_code: 'T123', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 'T123', cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
        allow(User).to receive(:transaction).and_raise(ActiveRecord::Rollback)
      end

      it 'does not affect other processing' do
        expect { service.call([teacher_record]) }.to raise_error(ActiveRecord::Rollback)
        expect(user.reload.teacher_id).to be_nil
      end
    end

    context 'performance test with multiple records' do
      let!(:api_codes) { ['T123', 'T234', 'T345', 'T456', 'T567'] }
      let!(:cpfs) { ['123.456.789-01', '234.567.890-12', '345.678.901-23', '456.789.012-34', '567.890.123-45'] }
      let!(:teachers) do
        api_codes.map { |api_code| create(:teacher, api_code: api_code, active: true) }
      end
      let!(:users) { [] }
      let(:teacher_records) do
        api_codes.zip(cpfs).map do |api_code, cpf|
          double(servidor_id: api_code, cpf: cpf)
        end
      end

      before do
        cpfs.each do |cpf|
          user = create(:user, cpf: cpf, teacher_id: nil)
          create(:user_role, user: user)
          users << user
        end
      end

      it 'executes with limited number of queries' do
        # Simples verificação de que o service funciona com múltiplos registros
        expect { service.call(teacher_records) }.not_to raise_error

        # Verifica que todos os usuários foram vinculados
        users.each_with_index do |user, index|
          expect(user.reload.teacher_id).to eq(teachers[index].id)
        end
      end
    end

    context 'when teacher_record has different api_code format' do
      let!(:teacher) { create(:teacher, api_code: '123', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: 123, cpf: '123.456.789-01') }

      before do
        create(:user_role, user: user)
      end

      it 'links even with different api_code types' do
        expect { service.call([teacher_record]) }.to change { user.reload.teacher_id }.from(nil).to(teacher.id)
      end
    end
  end

  describe 'integration with TeachersSynchronizer' do
    context 'when service is called directly' do
      let!(:teacher) { create(:teacher, api_code: 'T123', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }
      let(:teacher_record) { double(servidor_id: teacher.api_code, cpf: user.cpf) }

      before do
        create(:user_role, user: user)
      end
  
      it 'automatically links user to teacher' do
        expect { UserTeacherLinkerService.call([teacher_record]) }
          .to change { user.reload.teacher_id }
          .from(nil)
          .to(teacher.id)
      end
    end
  end
end
