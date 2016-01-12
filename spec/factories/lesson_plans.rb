FactoryGirl.define do
  factory :lesson_plan do
    lesson_plan_date '30/06/2020'
    contents 'Content'

    unity
  	classroom
  	association :school_calendar, factory: :school_calendar_with_one_step
  end
end
