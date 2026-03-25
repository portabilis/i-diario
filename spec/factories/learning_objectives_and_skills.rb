FactoryGirl.define do
  factory :learning_objectives_and_skill do
    sequence(:code) { |n| "EF0#{n}LP01" }
    description { Faker::Lorem.sentence }
    step { 'elementary_school' }
    grades { ['first_year'] }
    discipline { 'portuguese_language' }

    trait :child_school do
      sequence(:code) { |n| "EI0#{n}CO01" }
      step { 'child_school' }
      discipline { nil }
      field_of_experience { 'the_me_the_other_and_the_us' }
    end
  end
end
