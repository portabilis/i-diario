class SchoolCalendarStepSerializer < ActiveModel::Serializer
  attributes :id, :test_setting, :start_at, :end_at

  has_one :test_setting
end
