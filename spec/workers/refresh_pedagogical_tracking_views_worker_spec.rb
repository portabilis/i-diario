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
    before do
      # O REFRESH CONCURRENTLY não roda dentro da transação do teste e não
      # enxergaria dados não commitados — o modo exclusivo cobre o caminho real
      # de execução do SQL contra o banco.
      allow(subject).to receive(:populated?).and_return(false)
    end

    it 'refreshes the frequency materialized view without duplicated rows' do
      teacher = create(:teacher)
      classroom = create(:classroom, :with_classroom_semester_steps)
      disciplines = create_list(:discipline, 2)

      disciplines.each do |discipline|
        create(
          :teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: discipline
        )
      end
      frequency = create(
        :daily_frequency,
        classroom: classroom,
        discipline: disciplines.first,
        teacher: teacher
      )
      create(:unity_school_day, unity: classroom.unity, school_day: frequency.frequency_date)

      expect(MvwFrequencyBySchoolClassroomTeacher.count).to eq(0)

      subject.perform(entity.id, [])

      # Mesmo com dois vínculos de disciplina do professor na turma, o fato
      # (data, escola, turma, professor) aparece uma única vez na view.
      expect(
        MvwFrequencyBySchoolClassroomTeacher
          .pluck(:unity_id, :classroom_id, :teacher_id, :frequency_date)
      ).to eq([[classroom.unity_id, classroom.id, teacher.id, frequency.frequency_date]])
    end

    it 'keeps out of the frequency view the frequency whose teacher link was discarded' do
      teacher = create(:teacher)
      classroom = create(:classroom, :with_classroom_semester_steps)
      discipline = create(:discipline)

      teacher_discipline_classroom = create(
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

      # O vínculo é descartado depois do lançamento, como acontece quando o
      # professor deixa a turma.
      teacher_discipline_classroom.update!(discarded_at: Time.current)

      subject.perform(entity.id, [])

      expect(MvwFrequencyBySchoolClassroomTeacher.count).to eq(0)
    end

    it 'refreshes the content view for a record registered by discipline' do
      teacher = create(:teacher)
      classroom = create(:classroom, :score_type_numeric, :with_classroom_semester_steps)
      discipline = create(:discipline)

      create(
        :teacher_discipline_classroom,
        teacher: teacher,
        classroom: classroom,
        discipline: discipline
      )
      content_record = content_record_for(teacher, classroom)

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
      ).to eq([[classroom.unity_id, classroom.id, teacher.id, content_record.record_date]])
    end

    it 'refreshes the content view for a record registered by knowledge area' do
      teacher = create(:teacher)
      classroom = create(:classroom, :score_type_numeric, :with_classroom_semester_steps)
      discipline = create(:discipline)

      create(
        :teacher_discipline_classroom,
        teacher: teacher,
        classroom: classroom,
        discipline: discipline
      )
      content_record = content_record_for(teacher, classroom)

      KnowledgeAreaContentRecord.create!(
        content_record: content_record,
        knowledge_area_ids: [discipline.knowledge_area_id],
        teacher_id: teacher.id
      )
      create(
        :unity_school_day,
        unity: classroom.unity,
        school_day: content_record.record_date
      )

      subject.perform(entity.id, [])

      expect(
        MvwContentRecordBySchoolClassroomTeacher
          .pluck(:unity_id, :classroom_id, :teacher_id, :record_date)
      ).to eq([[classroom.unity_id, classroom.id, teacher.id, content_record.record_date]])
    end

    it 'registers the refresh timestamp of each view' do
      refreshed_at = Time.zone.local(Date.current.year, 5, 10, 4, 30)

      Timecop.freeze(refreshed_at) do
        subject.perform(entity.id, [])
      end

      expect(MaterializedViewRefresh.pluck(:view_name)).to match_array(described_class::VIEWS)
      expect(MaterializedViewRefresh.pluck(:refreshed_at)).to eq([refreshed_at, refreshed_at])
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

  describe '#refresh_statement' do
    it 'uses CONCURRENTLY when the view is populated' do
      expect(subject.send(:refresh_statement, 'mvw_test', true))
        .to eq('REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_test')
    end

    it 'uses the exclusive mode when the view was never populated' do
      expect(subject.send(:refresh_statement, 'mvw_test', false))
        .to eq('REFRESH MATERIALIZED VIEW mvw_test')
    end
  end

  describe '#populated?' do
    it 'returns true for the materialized views of the test database' do
      # As views são criadas populadas pela migration (WITH DATA).
      expect(subject.send(:populated?, MvwFrequencyBySchoolClassroomTeacher.table_name)).to eq(true)
    end

    it 'returns false for an unknown relation' do
      expect(subject.send(:populated?, 'mvw_unknown_view')).to eq(false)
    end
  end

  describe 'CONCURRENTLY precondition' do
    # O REFRESH CONCURRENTLY exige um índice único cobrindo todas as linhas da
    # view: sem ele o refresh noturno falharia apenas em produção.
    {
      'mvw_frequency_by_school_classroom_teachers' => 'idx_mvw_freq_unique',
      'mvw_content_record_by_school_classroom_teachers' => 'idx_mvw_content_unique'
    }.each do |view, index_name|
      it "keeps a unique index on #{view}" do
        definition = ActiveRecord::Base.connection.select_value(
          "SELECT indexdef FROM pg_indexes WHERE indexname = '#{index_name}'"
        )

        expect(definition).to include('CREATE UNIQUE INDEX')
        expect(definition).to include(view)
      end
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

  def content_record_for(teacher, classroom)
    content_record = create(
      :content_record,
      :with_contents,
      teacher: teacher,
      classroom: classroom
    )

    # O autosave do content_record dispara a validação de update, que exige o usuário corrente.
    content_record.current_user = User.current

    content_record
  end
end
