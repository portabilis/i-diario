FactoryGirl.define do
  factory :daily_note_student do
    daily_note
    student
    active true

    factory :current_daily_note_student do
      association :daily_note, factory: :current_daily_note
    end
  end
end
