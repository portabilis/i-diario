class SchoolCalendarStepSerializer < ActiveModel::Serializer
  attributes :id, :test_setting

  has_one :test_setting
end
