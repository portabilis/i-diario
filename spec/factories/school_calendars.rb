FactoryGirl.define do
  factory :school_calendar do
    year                     2020
    number_of_classes        5
    maximum_score            10
    number_of_decimal_places 2

    after(:build) do |school_calendar|
      school_calendar.steps.build(attributes_for(:school_calendar_step))
    end
  end
end