FactoryGirl.define do
  factory :descriptive_exam_student do
    student
    association :descriptive_exam, factory: [:descriptive_exam, :current]

    value { Faker::Lorem.paragraph }
  end
end
