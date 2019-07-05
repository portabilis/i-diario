FactoryGirl.define do
  factory :descriptive_exam_student do
    association :descriptive_exam, factory: [:descriptive_exam, :current]
    student
    value { Faker::Lorem.paragraph }
  end
end
