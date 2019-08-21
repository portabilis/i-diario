FactoryGirl.define do
  factory :daily_note do
    avaliation

    factory :current_daily_note do
      association :avaliation, factory: [:avaliation, :with_teacher_discipline_classroom]
    end
  end
end
