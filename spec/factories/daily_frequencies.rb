FactoryGirl.define do
  factory :daily_frequency do
    frequency_date "01/03/2016"

    unity
    classroom
    discipline
    association :school_calendar, factory: :school_calendar_with_one_step
  end
end
