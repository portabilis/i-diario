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
      it 'returns false' do
        expect(synchronization.worker_batch).to be_nil
        expect(synchronization.locked?).to be false
      end
    end

    context 'when worker_batch exists' do
      let!(:worker_batch) do
        create(:worker_batch,
          stateable: synchronization,
          started_at: 2.hours.ago,
          updated_at: 1.hour.ago
        )
      end

      context 'when average_time is nil' do
        before do
          allow(synchronization).to receive(:average_time).and_return(nil)
        end

        it 'uses default 60 minutes and returns false when time is under threshold' do
          # Permite que started_at seja ajustado para simular tempo de execução
          allow(synchronization).to receive(:time_running).and_return(100)
          # 100 < 60 * 3 = 180, then false (worker_batch.updated_at is 1 hour ago > 30 mins)
          expect(synchronization.locked?).to be false
        end

        it 'returns true when time exceeds default threshold and batch is stale' do
          allow(synchronization).to receive(:time_running).and_return(200)
          # 200 > 60 * 3 = 180, and worker_batch.updated_at is 1 hour ago > 30 mins
          expect(synchronization.locked?).to be true
        end
      end

      context 'when average_time is zero' do
        before do
          allow(synchronization).to receive(:average_time).and_return(0)
        end

        it 'uses default 60 minutes instead of zero' do
          allow(synchronization).to receive(:time_running).and_return(100)
          # Should use 60 as default, 100 < 60 * 3 = 180
          expect(synchronization.locked?).to be false
        end
      end

      context 'when average_time has a value' do
        before do
          allow(synchronization).to receive(:average_time).and_return(10)
        end

        it 'returns false when time is under threshold' do
          allow(synchronization).to receive(:time_running).and_return(25)
          # 25 < 10 * 3 = 30
          expect(synchronization.locked?).to be false
        end

        it 'returns false when worker_batch was updated recently' do
          worker_batch.update_column(:updated_at, 5.minutes.ago)
          allow(synchronization).to receive(:time_running).and_return(50)
          # 50 > 10 * 3 = 30, but worker_batch.updated_at is 5 mins ago < 30 mins
          expect(synchronization.locked?).to be false
        end

        it 'returns true when time exceeds threshold and batch is stale' do
          allow(synchronization).to receive(:time_running).and_return(50)
          # 50 > 10 * 3 = 30, and worker_batch.updated_at is 1 hour ago > 30 mins
          expect(synchronization.locked?).to be true
        end
      end
    end
  end

  describe '#cancel!' do
    let(:synchronization) { create(:ieducar_api_synchronization) }

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
  end
end
