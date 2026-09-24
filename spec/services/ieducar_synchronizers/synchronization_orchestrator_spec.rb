# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynchronizationOrchestrator, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:synchronization) do
    create(:ieducar_api_synchronization, status: ApiSynchronizationStatus::STARTED)
  end
  let(:worker_batch) { create(:worker_batch) }
  let(:unities) { '1,2' }
  let(:enqueued) { [] }

  before do
    allow(SynchronizerBuilder).to receive(:enqueue) { |params| enqueued << params }
  end

  def complete_worker(kind, meta_data)
    create(
      :worker_state,
      worker_batch: worker_batch,
      kind: kind,
      status: ApiSynchronizationStatus::COMPLETED,
      meta_data: meta_data
    )
  end

  def enqueue_next_after(klass, year, unity_api_code = unities)
    described_class.new(
      worker_batch,
      klass,
      entity_id: entity.id,
      year: year,
      unity_api_code: unity_api_code,
      current_years: true,
      synchronization: synchronization
    ).enqueue_next
  end

  def enqueued_years(klass)
    enqueued.select { |params| params[:klass] == klass }.map { |params| params[:years] }
  end

  describe '#enqueue_next' do
    context 'when a dependent filtered by year waits on a dependency that is not filtered by year' do
      let(:dependent) { 'TeacherDisciplineClassroomsSynchronizer' }

      it 'enqueues the dependent for the year when the dependency filtered by year finishes last' do
        complete_worker('SchoolCalendarDisciplineGradesSynchronizer', unity_api_code: unities)
        complete_worker('ClassroomsSynchronizer', year: '2026', unity_api_code: unities)

        enqueue_next_after('ClassroomsSynchronizer', '2026')

        expect(enqueued_years(dependent)).to eq([['2026']])
      end

      it 'enqueues the dependent once per year when the dependency without year finishes last' do
        complete_worker('ClassroomsSynchronizer', year: '2027', unity_api_code: unities)
        complete_worker('ClassroomsSynchronizer', year: '2026', unity_api_code: unities)
        complete_worker('SchoolCalendarDisciplineGradesSynchronizer', unity_api_code: unities)

        enqueue_next_after('SchoolCalendarDisciplineGradesSynchronizer', '2027,2026')

        expect(enqueued_years(dependent)).to eq([['2027'], ['2026']])
      end

      it 'enqueues only the years whose dependency filtered by year is already completed' do
        complete_worker('ClassroomsSynchronizer', year: '2027', unity_api_code: unities)
        complete_worker('SchoolCalendarDisciplineGradesSynchronizer', unity_api_code: unities)

        enqueue_next_after('SchoolCalendarDisciplineGradesSynchronizer', '2027,2026')

        expect(enqueued_years(dependent)).to eq([['2027']])
      end

      it 'checks the dependency of each year in the same unity when the synchronization runs by unity' do
        complete_worker('ClassroomsSynchronizer', year: '2027', unity_api_code: '1')
        complete_worker('ClassroomsSynchronizer', year: '2026', unity_api_code: '2')
        complete_worker('SchoolCalendarDisciplineGradesSynchronizer', unity_api_code: '1')

        enqueue_next_after('SchoolCalendarDisciplineGradesSynchronizer', '2027,2026', '1')

        tdc = enqueued.select { |params| params[:klass] == dependent }
        expect(tdc.map { |params| [params[:years], params[:unities_api_code]] }).to eq([[['2027'], ['1']]])
      end
    end

    it 'enqueues a dependent filtered by year for every year when its only dependency has no year' do
      complete_worker('StudentsSynchronizer', unity_api_code: unities)

      enqueue_next_after('StudentsSynchronizer', '2027,2026')

      expect(enqueued_years('StudentEnrollmentSynchronizer')).to eq([['2027'], ['2026']])
    end
  end
end
