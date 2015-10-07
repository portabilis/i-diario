FactoryGirl.define do
  factory :lesson_plan do
    lesson_plan_date '30/06/2020'
    contents 'Content'
    classes '1'

    unity
  	classroom
		discipline
  	school_calendar
  end
end
