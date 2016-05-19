class SchoolCalendarStepSerializer < ActiveModel::Serializer
  attributes :id, :test_setting, :start_at

  has_one :test_setting
end
