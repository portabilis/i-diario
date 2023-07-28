FactoryGirl.define do
  factory :custom_rounding_table do
    name { Faker::Name.unique }
    year { Date.current.year }
    unities { create_list(:unity, 2) }
    courses { create_list(:course, 2) }
    grades { create_list(:grade, 2) }
    rounded_avaliations { '{numerical_exam,school_term_recovery,final_recovery}' }
  end
end
