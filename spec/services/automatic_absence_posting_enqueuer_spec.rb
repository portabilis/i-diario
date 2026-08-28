require 'rails_helper'

RSpec.describe AutomaticAbsencePostingEnqueuer, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:first_step) { classroom.calendar.classroom_steps.find_by(step_number: 1) }
  let(:second_step) { classroom.calendar.classroom_steps.find_by(step_number: 2) }

  around do |example|
    entity.using_connection { example.run }
  end

  before do
    Sidekiq::Worker.clear_all
    GeneralConfiguration.current.update!(automatic_absence_posting: true)
  end

  def call(dates: [second_step.start_at], teacher_id: teacher.id, classroom_id: classroom.id, force_posting: false)
    described_class.call(
      entity_id: entity.id,
      classroom_id: classroom_id,
      frequency_dates: dates,
      teacher_id: teacher_id,
      force_posting: force_posting
    )
  end

  it 'enqueues the worker for the classroom, teacher and step of the frequency date' do
    call

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
  end

  it 'reads the flag from the persisted configuration' do
    expect(GeneralConfiguration.current.automatic_absence_posting).to eq(true)

    call

    expect(AutomaticAbsencePostingWorker.jobs.size).to eq(1)
  end

  it 'enqueues a single job for several dates of the same step' do
    call(dates: [second_step.start_at, second_step.start_at + 1.day, second_step.end_at])

    expect(AutomaticAbsencePostingWorker.jobs.size).to eq(1)
    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
  end

  it 'enqueues one job per step when the dates span more than one step' do
    call(dates: [first_step.start_at, second_step.start_at])

    expect(AutomaticAbsencePostingWorker.jobs.map { |job| job['args'].last(2) }).to contain_exactly(
      [1, false], [2, false]
    )
  end

  it 'accepts the frequency date as string' do
    call(dates: [second_step.end_at.to_s])

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
  end

  it 'propagates the force posting flag' do
    call(force_posting: true)

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, true)
  end

  it 'does nothing when the automatic posting is disabled' do
    GeneralConfiguration.current.update!(automatic_absence_posting: false)

    call

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'ignores dates outside the steps and keeps the valid ones' do
    expect(Rails.logger).to receive(:warn).with(hash_including(classroom_id: classroom.id))

    call(dates: [Date.new(classroom.year - 1, 1, 1), second_step.start_at])

    expect(AutomaticAbsencePostingWorker.jobs.size).to eq(1)
  end

  it 'does nothing without a teacher' do
    expect(Rails.logger).to receive(:warn).with(hash_including(classroom_id: classroom.id, teacher_id: nil))

    call(teacher_id: nil)

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'does nothing when the classroom does not exist' do
    expect(Rails.logger).to receive(:warn).with(hash_including(classroom_id: 0))

    call(classroom_id: 0)

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'reports the failure and does not raise when redis is unavailable' do
    allow(AutomaticAbsencePostingWorker).to receive(:perform_async).and_raise(Redis::CannotConnectError)

    expect(Rails.logger).to receive(:error).with(hash_including(classroom_id: classroom.id, step_number: 2))
    expect(Honeybadger).to receive(:notify)

    expect { call }.not_to raise_error
  end
end
