FactoryGirl.define do
  factory :daily_note do
    avaliation
    teacher_id { avaliation.teacher_id }

    factory :current_daily_note do
      association :avaliation, factory: :current_avaliation
    end
  end
end
