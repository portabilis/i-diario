require 'rails_helper'

RSpec.describe AutomaticAbsencePostingWorker, type: :worker do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:general_configuration) { GeneralConfiguration.new(automatic_absence_posting: true) }
  let(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
  let(:teacher) { create(:teacher) }
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps, unity: unity) }
  let(:step) { classroom.calendar.classroom_steps.first }

  around do |example|
    entity.using_connection { example.run }
  end

  before do
    Sidekiq::Worker.clear_all
    allow(GeneralConfiguration).to receive(:current).and_return(general_configuration)
    allow(IeducarApiConfiguration).to receive(:current).and_return(ieducar_api_configuration)
  end

  def perform(step_number: step.step_number, force_posting: false, classroom_id: classroom.id)
    described_class.new.perform(entity.id, classroom_id, teacher.id, step_number, force_posting)
  end

  def create_completed_posting(attributes)
    create(
      :ieducar_api_exam_posting,
      {
        post_type: ApiPostingTypes::ABSENCE,
        status: ApiSynchronizationStatus::COMPLETED,
        teacher: teacher,
        ieducar_api_configuration: ieducar_api_configuration,
        school_calendar_step: nil,
        school_calendar_classroom_step: step
      }.merge(attributes)
    ).tap { |posting| posting.worker_batch.update_columns(total_workers: 1) }
  end

  it 'creates an automatic absence posting restricted to the classroom and enqueues the exam posting worker' do
    expect { perform }.to change(IeducarApiExamPosting, :count).by(1)

    posting = IeducarApiExamPosting.last

    expect(posting).to have_attributes(
      automatic: true,
      post_type: ApiPostingTypes::ABSENCE,
      status: ApiSynchronizationStatus::STARTED,
      teacher_id: teacher.id,
      classroom_id: classroom.id,
      author_id: nil,
      ieducar_api_configuration_id: ieducar_api_configuration.id,
      school_calendar_classroom_step_id: step.id,
      school_calendar_step_id: nil
    )
    expect(posting.worker_batch.main_job_class).to eq('IeducarExamPostingWorker')
    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(entity.id, posting.id, nil, false)
  end

  it 'keeps the whole automatic flow out of the default queue' do
    perform

    expect(IeducarExamPostingWorker.jobs.first['queue']).to eq(described_class::QUEUE)
  end

  it 'uses the school calendar step when the classroom has no calendar of its own' do
    school_calendar = create(:school_calendar, :with_semester_steps, unity: unity)
    classroom_without_calendar = create(:classroom, unity: unity)

    perform(classroom_id: classroom_without_calendar.id, step_number: 2)

    expect(IeducarApiExamPosting.last).to have_attributes(
      classroom_id: classroom_without_calendar.id,
      school_calendar_step_id: school_calendar.steps.find_by(step_number: 2).id,
      school_calendar_classroom_step_id: nil
    )
  end

  it 'uses the last completed automatic posting of the same classroom as the incremental base' do
    create_completed_posting(automatic: false, classroom: nil, author: create(:user))
    other_classroom_posting = create_completed_posting(automatic: true, classroom: create(:classroom, unity: unity))
    same_classroom_posting = create_completed_posting(automatic: true, classroom: classroom)

    perform

    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(
      entity.id,
      IeducarApiExamPosting.last.id,
      same_classroom_posting.id,
      false
    )
    expect(IeducarApiExamPosting.last.id).not_to eq(other_classroom_posting.id)
  end

  it 'propagates the force posting flag' do
    perform(force_posting: true)

    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(entity.id, IeducarApiExamPosting.last.id, nil, true)
  end

  it 'does nothing when the automatic posting is disabled' do
    general_configuration.automatic_absence_posting = false

    expect { perform }.not_to change(IeducarApiExamPosting, :count)
    expect(IeducarExamPostingWorker.jobs).to be_empty
  end

  it 'does nothing when the i-Educar API is not configured' do
    allow(IeducarApiConfiguration).to receive(:current).and_return(IeducarApiConfiguration.new)

    expect { perform }.not_to change(IeducarApiExamPosting, :count)
  end

  it 'does nothing when the classroom has no step with the given number' do
    expect { perform(step_number: 9) }.not_to change(IeducarApiExamPosting, :count)
  end

  it 'does nothing when the classroom does not exist' do
    expect { perform(classroom_id: 0) }.not_to change(IeducarApiExamPosting, :count)
  end
end
