FactoryGirl.define do
  factory :system_notification_target do
    association :system_notification
    association :user
    read false
    read_at nil
  end
end