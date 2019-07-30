FactoryGirl.define do
  factory :ieducar_api_exam_posting do
    worker_batch
    ieducar_api_configuration
    school_calendar_step
    association :author, factory: :user
  end
end
