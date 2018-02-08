FactoryGirl.define do
  factory :avaliation do
    test_date    '03/02/2020'
    classes      '1'
    description  'Avaliation description'

    discipline
    classroom
    association :school_calendar, factory: :school_calendar_with_one_step
    test_setting

    factory :current_avaliation do
      test_date { Time.zone.today }
      association :school_calendar, factory: :current_school_calendar_with_one_step
      association :classroom, factory: :classroom_numeric_and_concept
    end
  end
end
