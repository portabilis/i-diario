FactoryGirl.define do
  factory :teaching_plan do
    year 2015
    school_term_type SchoolTermTypes::BIMESTER
    school_term      Bimesters::FIRST

    association :classroom
    association :discipline
  end
end