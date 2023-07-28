FactoryGirl.define do
  factory :active_search do
    student_enrollment
    observations { Faker::Lorem.unique.sentence }
    start_date { '2022-02-01' }
    status { ActiveSearchStatus::IN_PROGRESS }
    sequence(:api_code, &:to_s)
  end

  trait :with_status_abandonment do
    after(:create) do |active_search|
      active_search.status = ActiveSearchStatus::ABANDONMENT
      active_search.end_date = '2022-05-01'
      active_search.save!
    end
  end

  trait :with_status_return do
    after(:create) do |active_search|
      active_search.status = ActiveSearchStatus::RETURN
      active_search.end_date = '2022-03-01'
      active_search.save!
    end
  end

  trait :with_status_return_with_justification do
    after(:create) do |active_search|
      active_search.status = ActiveSearchStatus::RETURN_WITH_JUSTIFICATION
      active_search.end_date = '2022-02-10'
      active_search.save!
    end
  end
end
