require 'rails_helper'

RSpec.describe IeducarExamPostingLauncher, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
  let(:author) { create(:user) }
  let(:teacher) { create(:teacher) }
  let(:step) { create(:school_calendar, :with_one_step).steps.first }
  let(:attributes) {
    {
      post_type: ApiPostingTypes::ABSENCE,
      author: author,
      teacher: teacher,
      ieducar_api_configuration: ieducar_api_configuration,
      school_calendar_step: step,
      automatic: false
    }
  }

  around do |example|
    entity.using_connection { example.run }
  end

  before { Sidekiq::Worker.clear_all }

  def call(force_posting: false)
    described_class.call(attributes: attributes, entity_id: entity.id, force_posting: force_posting)
  end

  it 'creates a started posting with its worker batch and enqueues the exam posting worker' do
    posting = call

    expect(posting).to have_attributes(
      attributes.merge(status: ApiSynchronizationStatus::STARTED)
    )
    expect(posting.worker_batch).to have_attributes(main_job_class: 'IeducarExamPostingWorker')
    expect(posting.worker_batch.main_job_id).to eq(IeducarExamPostingWorker.jobs.first['jid'])
    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(entity.id, posting.id, nil, false)
  end

  it 'enqueues on the default queue when none is given' do
    call

    expect(IeducarExamPostingWorker.jobs.first['queue']).to eq('exam_posting')
  end

  it 'enqueues on the given queue' do
    described_class.call(attributes: attributes, entity_id: entity.id, queue: 'critical')

    expect(IeducarExamPostingWorker.jobs.first['queue']).to eq('critical')
  end

  it 'uses the last completed posting with the same attributes as the incremental base' do
    create(:ieducar_api_exam_posting, attributes.merge(status: ApiSynchronizationStatus::COMPLETED))
    last_completed = create(:ieducar_api_exam_posting, attributes.merge(status: ApiSynchronizationStatus::COMPLETED))
    create(:ieducar_api_exam_posting, attributes.merge(status: ApiSynchronizationStatus::ERROR))

    posting = call(force_posting: 'true')

    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(entity.id, posting.id, last_completed.id, 'true')
  end

  it 'ignores completed postings with a different automatic flag' do
    create(
      :ieducar_api_exam_posting,
      attributes.merge(status: ApiSynchronizationStatus::COMPLETED, automatic: true, classroom: create(:classroom))
    )

    posting = call

    expect(IeducarExamPostingWorker).to have_enqueued_sidekiq_job(entity.id, posting.id, nil, false)
  end
end
