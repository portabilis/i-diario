FactoryGirl.define do
  factory :observation_diary_record_note do
    sequence(:description) { |n| "Description Example #{n}" }

    association(
      :observation_diary_record,
      factory: :observation_diary_record_with_notes
    )
  end
end
