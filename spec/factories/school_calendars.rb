FactoryGirl.define do
  factory :school_calendar do
    sequence(:year) { |n| 2020 + n }
    number_of_classes        5

    after(:build) do |school_calendar|
      school_calendar.steps.build(attributes_for(:school_calendar_step, start_at: "01/01/#{school_calendar.year}", end_at: "30/06/#{school_calendar.year}"))
    end
  end
end