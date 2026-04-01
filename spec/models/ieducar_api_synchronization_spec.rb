require 'rails_helper'

RSpec.describe IeducarApiSynchronization, :type => :model do
  context "Associations" do
    it { should belong_to :ieducar_api_configuration }
    it { should belong_to :author }
  end

  context "Validations" do
    it { should validate_presence_of :ieducar_api_configuration }

    it do
      subject.ieducar_api_configuration = create(:ieducar_api_configuration)
      subject.status = ApiSynchronizationStatus::STARTED
      subject.save!
      is_expected.to validate_uniqueness_of(:ieducar_api_configuration_id).scoped_to(:status)
    end

    it do
      subject.ieducar_api_configuration = create(:ieducar_api_configuration)
      subject.status = ApiSynchronizationStatus::ERROR
      subject.save!
      is_expected.to_not validate_uniqueness_of(:ieducar_api_configuration_id).scoped_to(:status)
    end
  end

  describe '#mark_as_error!' do
    it 'should mark synchronization as error and set the error message' do
      subject = create(:ieducar_api_synchronization)

      subject.mark_as_error!('foo', 'bar')

      expect(subject.status).to eq ApiSynchronizationStatus::ERROR
      expect(subject.error_message).to eq 'foo'
      expect(subject.full_error_message).to eq 'bar'
    end
  end

  describe '#mark_as_completed!' do
    it 'should mark synchronization as completed' do
      subject = create(:ieducar_api_synchronization)

      subject.mark_as_completed!

      expect(subject.status).to eq ApiSynchronizationStatus::COMPLETED
    end
  end

  describe "#notified!" do
    it "marks synchronization as notified" do
      expect(subject).to receive(:update_column).with(:notified, true)

      subject.notified!
    end
  end

  describe '#locked?' do
    let(:synchronization) { create(:ieducar_api_synchronization) }

    context 'when worker_batch is nil' do
      it 'returns false without raising error' do
        expect(synchronization.worker_batch).to be_nil
        expect(synchronization.locked?).to be false
      end
    end

    context 'when worker_batch exists' do
      let!(:worker_batch) do
        wb = create(:worker_batch, stateable: synchronization, started_at: 2.hours.ago)
        wb.update_column(:updated_at, 1.hour.ago)
        wb
      end

      before { synchronization.reload }

      it 'returns false when worker_batch was updated recently' do
        worker_batch.update_column(:updated_at, 5.minutes.ago)
        expect(synchronization.locked?).to be false
      end

      it 'does not raise error when average_time is nil' do
        allow(synchronization).to receive(:average_time).and_return(nil)
        expect { synchronization.locked? }.not_to raise_error
      end

      it 'does not raise error when average_time is zero' do
        allow(synchronization).to receive(:average_time).and_return(0)
        expect { synchronization.locked? }.not_to raise_error
      end

      # Usa 15 minutos como padrão quando average_time é nil/zero
      # Threshold = 15 * 3 = 45 minutos
      it 'uses default 15 minutes when average_time is nil and returns correct result' do
        allow(synchronization).to receive(:average_time).and_return(nil)
        allow(synchronization).to receive(:time_running).and_return(50)
        # 50 > 15 * 3 = 45, and worker_batch.updated_at 1 hour ago > 30 mins
        expect(synchronization.locked?).to be true
      end
    end
  end

  describe '#cancel!' do
    let(:synchronization) { create(:ieducar_api_synchronization, author: create(:user)) }

    it 'marks synchronization as error with default timeout message' do
      synchronization.cancel!

      expect(synchronization.status).to eq ApiSynchronizationStatus::ERROR
      expect(synchronization.error_message).to eq I18n.t('ieducar_api_synchronization.timedout')
    end

    it 'marks synchronization as error with custom message' do
      synchronization.cancel!(false, nil, 'Custom error')

      expect(synchronization.status).to eq ApiSynchronizationStatus::ERROR
      expect(synchronization.error_message).to eq 'Custom error'
    end

    context 'when restart is true' do
      it 'starts a new synchronization after canceling' do
        entity = Entity.first || create(:entity)
        # cancel! usa IeducarApiConfiguration.current, não a config da synchronization
        allow(IeducarApiConfiguration).to receive(:current).and_return(synchronization.ieducar_api_configuration)
        expect(synchronization.ieducar_api_configuration).to receive(:start_synchronization).with(synchronization.author, entity.id)

        synchronization.cancel!(true, entity.id)
      end
    end
  end
end
