require 'rails_helper'

RSpec.describe AutomaticAbsencePostingEnqueuer, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:general_configuration) { GeneralConfiguration.new(automatic_absence_posting: true) }
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:second_step) { classroom.calendar.classroom_steps.find_by(step_number: 2) }

  around do |example|
    entity.using_connection { example.run }
  end

  before do
    Sidekiq::Worker.clear_all
    allow(GeneralConfiguration).to receive(:current).and_return(general_configuration)
  end

  def call(frequency_date: second_step.start_at, teacher_id: teacher.id, classroom_id: classroom.id, force_posting: false)
    described_class.call(
      entity_id: entity.id,
      classroom_id: classroom_id,
      frequency_date: frequency_date,
      teacher_id: teacher_id,
      force_posting: force_posting
    )
  end

  it 'enqueues the worker for the classroom, teacher and step of the frequency date' do
    call

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
  end

  it 'accepts the frequency date as string' do
    call(frequency_date: second_step.end_at.to_s)

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, false)
  end

  it 'propagates the force posting flag' do
    call(force_posting: true)

    expect(AutomaticAbsencePostingWorker).to have_enqueued_sidekiq_job(entity.id, classroom.id, teacher.id, 2, true)
  end

  it 'does nothing when the automatic posting is disabled' do
    general_configuration.automatic_absence_posting = false

    call

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'does nothing when the frequency date is outside the steps' do
    call(frequency_date: Date.new(classroom.year - 1, 1, 1))

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'does nothing without a teacher' do
    call(teacher_id: nil)

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end

  it 'does nothing when the classroom does not exist' do
    call(classroom_id: 0)

    expect(AutomaticAbsencePostingWorker.jobs).to be_empty
  end
end
