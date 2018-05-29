FactoryGirl.define do
  factory :worker_state do
    job_id 123
    kind 'worker'
    user
  end
end
