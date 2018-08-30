FactoryGirl.define do
  factory :worker_batch do
    main_job_class 'IeducarExamPostingWorker'
    main_job_id '123'
  end
end
