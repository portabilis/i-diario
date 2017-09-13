FactoryGirl.define do
  factory :daily_frequency do
    frequency_date "01/03/2016"

    unity
    classroom
    discipline
    class_number 1
    association :school_calendar, factory: :school_calendar_with_one_step
  end
end
