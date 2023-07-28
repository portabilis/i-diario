class DailyFrequencyStudentSerializer < ActiveModel::Serializer
  attributes :id, :active, :present, :daily_frequency_id, :updated_at, :created_at, :sequence, :student

  def student
    ::StudentSerializer.new(object.student).attributes
  end
end
