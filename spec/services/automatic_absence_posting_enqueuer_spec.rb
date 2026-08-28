require 'rails_helper'

RSpec.describe AutomaticAbsencePostingEnqueuer, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  # A data corrente da suíte cai dentro da janela de lançamento da primeira etapa e fora da segunda.
  let(:open_step) { classroom.calendar.classroom_steps.find_by(step_number: 1) }
  let(:closed_step) { classroom.calendar.classroom_steps.find_by(step_number: 2) }

  around do |example|
    entity.using_connection { example.run }
  end

  # Usuário sem a permissão de envio sem restrição de data: é ela que libera o envio fora da janela.
  let(:user) do
    create(:user_with_user_role, admin: false).tap do |created_user|
      created_user.current_user_role = created_user.user_roles.first
      permission = created_user.current_user_role.role.permissions.find_or_initialize_by(
        feature: Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS
      )
      permission.permission = Permissions::READ
      permission.save!
    end
  end

  before do
    Sidekiq::Worker.clear_all
    GeneralConfiguration.current.update!(automatic_absence_posting: true)
    User.current = user
  end

  after { User.current = nil }

  def call(dates: [open_step.start_at], teacher_id: teacher.id, classroom_id: classroom.id, force_posting: false)
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

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 1, false)
  end

  it 'reads the flag from the persisted configuration' do
    expect(GeneralConfiguration.current.automatic_absence_posting).to eq(true)

    call

    expect(AutomaticAbsencePostingWorker.jobs.size).to eq(1)
  end

  it 'enqueues a single job for several dates of the same step' do
    call(dates: [open_step.start_at, open_step.start_at + 1.day, open_step.end_at])

    expect(AutomaticAbsencePostingWorker.jobs.size).to eq(1)
    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 1, false)
  end

  it 'enqueues one job per step when the dates span more than one open step' do
    closed_step.update!(start_date_for_posting: open_step.start_date_for_posting)

    call(dates: [open_step.start_at, closed_step.start_at])

    expect(AutomaticAbsencePostingWorker.jobs.map { |job| job['args'][3] }).to contain_exactly(1, 2)
  end

  it 'accepts the frequency date as string' do
    call(dates: [open_step.end_at.to_s])

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 1, false)
  end

  it 'propagates the force posting flag' do
    call(force_posting: true)

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 1, true)
  end

  it 'does nothing when the automatic posting is disabled' do
    GeneralConfiguration.current.update!(automatic_absence_posting: false)

    call

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'ignores dates outside the steps and keeps the valid ones' do
    expect(Rails.logger).to receive(:warn).with(hash_including(classroom_id: classroom.id))

    call(dates: [Date.new(classroom.year - 1, 1, 1), open_step.start_at])

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

    expect(Rails.logger).to receive(:error).with(hash_including(classroom_id: classroom.id, step_number: 1))
    expect(Honeybadger).to receive(:notify)

    expect { call }.not_to raise_error
  end

  # Mesma regra do envio manual: fora da janela de lançamento o professor não envia pela tela, e o
  # envio automático não pode contornar isso.
  context 'when the posting window of the step is closed' do
    it 'does not enqueue' do
      call(dates: [closed_step.start_at])

      expect(AutomaticAbsencePostingWorker.jobs).to be_empty
    end

    it 'enqueues for a user allowed to post without date restrictions' do
      User.current = create(:user, admin: true)

      call(dates: [closed_step.start_at])

      expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
    end

    it 'keeps the steps whose window is still open' do
      call(dates: [open_step.start_at, closed_step.start_at])

      expect(AutomaticAbsencePostingWorker.jobs.map { |job| job['args'][3] }).to eq([1])
    end
  end
end
