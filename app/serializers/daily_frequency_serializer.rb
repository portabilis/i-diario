class DailyFrequencySerializer < ActiveModel::Serializer
  attributes :id, :unity_id, :unity_name, :classroom_id, :classroom_name,
             :frequency_date, :discipline_id, :discipline_name, :class_number

  has_many :students

  def unity_name
    object.unity.name
  end

  def classroom_name
    object.classroom.description
  end

  def discipline_name
    object.discipline.try(:to_s)
  end
end
