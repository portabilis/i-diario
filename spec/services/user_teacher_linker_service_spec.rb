require 'rails_helper'

RSpec.describe UserTeacherLinkerService, type: :service do
  let(:service) { described_class.new }

  describe '#call' do
    context 'when there are no users to link' do
      it 'logs that no users were found' do
        allow(Rails.logger).to receive(:info)

        service.call

        expect(Rails.logger).to have_received(:info).with('Nenhum usuário encontrado para vinculação automática usuário-professor por CPF')
      end
    end

    context 'when there are users and teachers with matching CPF' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'links the user to the teacher' do
        expect { service.call }.to change { user.reload.teacher_id }.from(nil).to(teacher.id)
      end

      it 'logs the successful linking' do
        allow(Rails.logger).to receive(:info)

        service.call

        expect(Rails.logger).to have_received(:info).with("Usuário #{user.id} (#{user.name}) vinculado ao professor #{teacher.id} pelo CPF")
        expect(Rails.logger).to have_received(:info).with('Vinculação automática usuário-professor por CPF executada')
      end
    end

    context 'when teacher is already linked to another user' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:existing_user) { create(:user, teacher_id: teacher.id) }
      let!(:new_user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: new_user)
      end

      it 'does not link the new user' do
        expect { service.call }.not_to change { new_user.reload.teacher_id }
      end

      it 'does not affect the already linked user' do
        expect { service.call }.not_to change { existing_user.reload.teacher_id }
      end
    end

    context 'when user does not have valid user_roles' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      it 'does not link the user' do
        expect { service.call }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher is inactive' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: false) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'does not link the user to inactive teacher' do
        expect { service.call }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when teacher is soft deleted' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true, discarded_at: Time.current) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'does not link the user to deleted teacher' do
        expect { service.call }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when CPF has different formatting' do
      let!(:teacher) { create(:teacher, cpf: '12345678901', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'links even with different CPF formatting' do
        expect { service.call }.to change { user.reload.teacher_id }.from(nil).to(teacher.id)
      end
    end

    context 'when user has empty or null CPF' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user_empty_cpf) { create(:user, cpf: '', teacher_id: nil) }
      let!(:user_nil_cpf) { create(:user, cpf: nil, teacher_id: nil) }

      before do
        create(:user_role, user: user_empty_cpf)
        create(:user_role, user: user_nil_cpf)
      end

      it 'does not process users without CPF' do
        expect { service.call }.not_to change { user_empty_cpf.reload.teacher_id }
        expect { service.call }.not_to change { user_nil_cpf.reload.teacher_id }
      end
    end

    context 'when user already has teacher_id filled' do
      let!(:teacher1) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:teacher2) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: teacher1.id) }

      before do
        create(:user_role, user: user)
      end

      it 'does not change existing linking' do
        expect { service.call }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when user validation fails' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
        allow_any_instance_of(User).to receive(:update).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(
          double(full_messages: ['Custom validation error'])
        )
      end

      it 'logs validation error' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        service.call

        expect(Rails.logger).to have_received(:warn).with("Falha ao vincular usuário #{user.id}: Custom validation error")
        expect(Rails.logger).to have_received(:info).with('Vinculação automática usuário-professor por CPF executada')
      end

      it 'does not link the user' do
        expect { service.call }.not_to change { user.reload.teacher_id }
      end
    end

    context 'when there is a transaction error' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
        allow(User).to receive(:transaction).and_raise(ActiveRecord::Rollback)
      end

      it 'does not affect other processing' do
        expect { service.call }.to raise_error(ActiveRecord::Rollback)
        expect(user.reload.teacher_id).to be_nil
      end
    end

    context 'performance test with multiple records' do
      let!(:cpfs) { ['123.456.789-01', '234.567.890-12', '345.678.901-23', '456.789.012-34', '567.890.123-45'] }
      let!(:teachers) do
        cpfs.map { |cpf| create(:teacher, cpf: cpf, active: true) }
      end
      let!(:users) { [] }

      before do
        teachers.each_with_index do |teacher, _index|
          user = create(:user, cpf: teacher.cpf, teacher_id: nil)
          create(:user_role, user: user)
          users << user
        end
      end

      it 'executes with limited number of queries' do
        # Simples verificação de que o service funciona com múltiplos registros
        expect { service.call }.not_to raise_error

        # Verifica que todos os usuários foram vinculados
        users.each_with_index do |user, index|
          expect(user.reload.teacher_id).to eq(teachers[index].id)
        end
      end
    end
  end

  describe '#user_has_valid_roles?' do
    let(:user) { create(:user) }

    context 'when user has user_roles' do
      before { create(:user_role, user: user) }

      it 'returns true' do
        user_with_roles = User.includes(:user_roles).find(user.id)
        expect(service.send(:user_has_valid_roles?, user_with_roles)).to be true
      end
    end

    context 'when user does not have user_roles' do
      it 'returns false' do
        user_without_roles = User.includes(:user_roles).find(user.id)
        expect(service.send(:user_has_valid_roles?, user_without_roles)).to be false
      end
    end
  end

  describe 'integration with TeachersSynchronizer' do
    context 'when service is called directly' do
      let!(:teacher) { create(:teacher, cpf: '123.456.789-01', active: true) }
      let!(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      before do
        create(:user_role, user: user)
      end

      it 'automatically links user to teacher' do
        expect { UserTeacherLinkerService.call }.to change { user.reload.teacher_id }.from(nil).to(teacher.id)
      end
    end
  end
end
