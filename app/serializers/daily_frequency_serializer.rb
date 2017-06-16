class DailyFrequencySerializer < ActiveModel::Serializer
  attributes :id, :unity_id, :classroom_id, :frequency_date, :discipline_id, :class_number

  has_many :students
end
