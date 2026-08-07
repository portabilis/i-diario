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
    it 'refreshes the frequency materialized view' do
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

    it 'refreshes the content record materialized view' do
      teacher = create(:teacher)
      classroom = create(:classroom, :score_type_numeric, :with_classroom_semester_steps)
      discipline = create(:discipline)

      create(
        :teacher_discipline_classroom,
        teacher: teacher,
        classroom: classroom,
        discipline: discipline
      )
      content_record = create(
        :content_record,
        :with_contents,
        teacher: teacher,
        classroom: classroom
      )
      # O autosave do content_record dispara a validação de update, que exige o usuário corrente.
      content_record.current_user = User.current

      create(
        :discipline_content_record,
        content_record: content_record,
        discipline: discipline,
        teacher_id: teacher.id
      )
      create(
        :unity_school_day,
        unity: classroom.unity,
        school_day: content_record.record_date
      )

      expect(MvwContentRecordBySchoolClassroomTeacher.count).to eq(0)

      subject.perform(entity.id, [])

      expect(
        MvwContentRecordBySchoolClassroomTeacher
          .pluck(:unity_id, :classroom_id, :teacher_id, :record_date)
          .uniq
      ).to eq([[classroom.unity_id, classroom.id, teacher.id, content_record.record_date]])
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

    it 'skips a disabled entity without refreshing and keeps the chain going' do
      disabled_entity = create(:entity, domain: 'disabled.test.host', disabled: true)

      expect(subject).not_to receive(:refresh)

      subject.perform(disabled_entity.id, [111])

      expect(described_class).to have_enqueued_sidekiq_job(111, [])
    end

    it 'skips an entity that no longer exists without refreshing' do
      expect(subject).not_to receive(:refresh)

      subject.perform(0, [111])

      expect(described_class).to have_enqueued_sidekiq_job(111, [])
    end
  end

  describe '.enqueue_next' do
    it 'enqueues the head of the list carrying the remaining entities' do
      described_class.enqueue_next([111, 222, 333])

      expect(described_class).to have_enqueued_sidekiq_job(111, [222, 333])
      expect(described_class.jobs.size).to eq(1)
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
