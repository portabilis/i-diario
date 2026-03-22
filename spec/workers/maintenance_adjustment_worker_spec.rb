require 'rails_helper'

RSpec.describe MaintenanceAdjustmentWorker do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  describe '#perform' do
    let(:user) { create(:user, :with_user_role_administrator) }
    let(:unity) { create(:unity) }
    let(:maintenance_adjustment) do
      MaintenanceAdjustment.create!(
        year: Date.current.year,
        kind: MaintenanceAdjustmentKinds::ABSENCE_ADJUSTMENTS,
        observations: 'Adjust absences after fixing an exam rule',
        status: MaintenanceAdjustmentStatus::PENDING,
        unities: [unity]
      )
    end

    before do
      allow(SystemNotificationCreator).to receive(:create!)
      allow(Honeybadger).to receive(:notify)
    end

    it 'marca o ajuste como concluido e limpa a mensagem de erro persistida' do
      allow(AbsenceAdjustmentsService).to receive(:adjust)

      described_class.new.perform(entity.id, [unity.id], user.id, maintenance_adjustment.id)

      maintenance_adjustment.reload

      expect(maintenance_adjustment.status).to eq(MaintenanceAdjustmentStatus::COMPLETED)
      expect(maintenance_adjustment.error_message).to be_nil
      expect(AbsenceAdjustmentsService).to have_received(:adjust).with([unity.id], maintenance_adjustment.year)
      expect(SystemNotificationCreator).to have_received(:create!).with(
        hash_including(
          source: maintenance_adjustment,
          title: I18n.t('maintenance_adjustment_worker.success.title'),
          description: I18n.t('maintenance_adjustment_worker.success.description'),
          users: [user]
        )
      )
      expect(Honeybadger).not_to have_received(:notify)
    end

    it 'marca o ajuste como erro, persiste a mensagem e notifica o usuario' do
      allow(AbsenceAdjustmentsService).to receive(:adjust).and_raise(StandardError, 'Regra de avaliacao inconsistente')

      described_class.new.perform(entity.id, [unity.id], user.id, maintenance_adjustment.id)

      maintenance_adjustment.reload

      expect(maintenance_adjustment.status).to eq(MaintenanceAdjustmentStatus::ERROR)
      expect(maintenance_adjustment.error_message).to eq('Regra de avaliacao inconsistente')
      expect(Honeybadger).to have_received(:notify).with(instance_of(StandardError))
      expect(SystemNotificationCreator).to have_received(:create!).with(
        hash_including(
          source: maintenance_adjustment,
          title: I18n.t('maintenance_adjustment_worker.error.title'),
          description: I18n.t(
            'maintenance_adjustment_worker.error.description',
            error_message: 'Regra de avaliacao inconsistente'
          ),
          users: [user]
        )
      )
    end
  end
end
