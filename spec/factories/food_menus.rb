FactoryGirl.define do
  factory :food_***REMOVED*** do
    quantity 1.00

    association :***REMOVED***
    association :food, factory: :food_with_***REMOVED***
  end
end
