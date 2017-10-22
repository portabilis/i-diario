class DailyFrequencyStudentSerializer < ActiveModel::Serializer
  attributes :id, :active, :present, :daily_frequency_id, :updated_at, :created_at, :sequence

  has_one :student
end
