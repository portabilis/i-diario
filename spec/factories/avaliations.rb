FactoryGirl.define do
  factory :avaliation do
    test_date    '03/02/2020'
    class_number '1'
    description  'Avaliation description'

    test_setting
    school_calendar
    discipline
  end
end