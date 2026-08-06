# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshPedagogicalTrackingViewsWorker, type: :worker do
  let(:entity) { Entity.find_by_domain('test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    described_class.clear
  end

  describe '#perform' do
    it 'refreshes the materialized views' do
      teacher = create(:teacher)
      classroom = create(:classroom, :with_classroom_semester_steps)
      discipline = create(:discipline)

      create(
        :teacher_discipline_classroom,
        teacher: teacher,
        classroom: classroom,
        discipline: discipline
      )
      frequency = create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        teacher: teacher
      )
      create(:unity_school_day, unity: classroom.unity, school_day: frequency.frequency_date)

      expect(MvwFrequencyBySchoolClassroomTeacher.count).to eq(0)

      subject.perform(entity.id, [])

      expect(
        MvwFrequencyBySchoolClassroomTeacher
          .pluck(:unity_id, :classroom_id, :teacher_id, :frequency_date)
          .uniq
      ).to eq([[classroom.unity_id, classroom.id, teacher.id, frequency.frequency_date]])
    end

    it 'enqueues the next entity of the chain with the remaining ones' do
      allow(subject).to receive(:refresh)

      subject.perform(entity.id, [111, 222])

      expect(described_class).to have_enqueued_sidekiq_job(111, [222])
    end

    it 'does not enqueue anything when it is the last entity of the chain' do
      allow(subject).to receive(:refresh)

      subject.perform(entity.id, [])

      expect(described_class.jobs).to be_empty
    end

    it 'raises and does not enqueue the next entity when a refresh fails' do
      allow(subject).to receive(:refresh)
        .and_raise(ActiveRecord::StatementInvalid, 'refresh failed')

      expect {
        subject.perform(entity.id, [111])
      }.to raise_error(ActiveRecord::StatementInvalid)

      expect(described_class.jobs).to be_empty
    end
  end

  describe '.enqueue_next' do
    it 'skips an entity whose enqueue is rejected by the unique lock and continues the chain' do
      # perform_async retorna nil quando o lock único rejeita o job (entidade já
      # em fila/execução) — a cadeia deve pular para a próxima entidade.
      allow(described_class).to receive(:perform_async).with(111, [222, 333]).and_return(nil)
      allow(described_class).to receive(:perform_async).with(222, [333]).and_return('jid')

      described_class.enqueue_next([111, 222, 333])

      expect(described_class).to have_received(:perform_async).with(222, [333])
      expect(described_class).not_to have_received(:perform_async).with(333, [])
    end

    it 'does not enqueue anything when the list is empty' do
      described_class.enqueue_next([])

      expect(described_class.jobs).to be_empty
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [entity.id, [111, 222]] } }
    let(:exception) { ActiveRecord::StatementInvalid.new('refresh failed') }

    it 'notifies Honeybadger with the entity context' do
      expect(Honeybadger).to receive(:notify)
        .with(exception, context: { entity_id: entity.id })

      described_class.sidekiq_retries_exhausted_block.call(job, exception)
    end

    it 'continues the chain with the remaining entities' do
      allow(Honeybadger).to receive(:notify)

      described_class.sidekiq_retries_exhausted_block.call(job, exception)

      expect(described_class).to have_enqueued_sidekiq_job(111, [222])
    end
  end
end
