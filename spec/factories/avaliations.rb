FactoryGirl.define do
  factory :avaliation do
    test_date    '03/02/2020'
    classes      '1'
    description  'Avaliation description'

    unity
    discipline
    classroom
    school_calendar
    test_setting
  end
end