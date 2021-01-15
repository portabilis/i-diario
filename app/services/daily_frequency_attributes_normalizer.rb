class DailyFrequencyAttributesNormalizer
  PRESENCE_DEFAULT = '0'.freeze

  attr_reader :daily_frequency_students_params, :daily_frequency_attributes

  def initialize(daily_frequency_students_params, daily_frequency_attributes)
    @daily_frequency_students_params = daily_frequency_students_params
    @daily_frequency_attributes = daily_frequency_attributes
  end

  def normalize_daily_frequency!
    daily_frequency_attributes[:discipline_id] = daily_frequency_attributes[:discipline_id].presence

    if daily_frequency_attributes[:discipline_id]
      daily_frequency_students_params[:class_number] = class_number(daily_frequency_students_params[:class_number])
    else
      daily_frequency_students_params[:class_number] = nil
    end

    daily_frequency_attributes[:class_number] = daily_frequency_students_params[:class_number]
  end

  def normalize_daily_frequency_students!(daily_frequency_record, daily_frequency_students_params)
    daily_frequency_students_params[:students_attributes].each_value do |daily_frequency_student|
      daily_frequency_student[:present] = PRESENCE_DEFAULT if daily_frequency_student[:present].blank?
    end

    update_daily_frequency_students_params(daily_frequency_record, daily_frequency_students_params)
  end

  private

  def class_number(class_number_attribute)
    return if class_number_attribute.to_i.zero?

    class_number_attribute
  end

  def get_not_persisted_daily_frequency_students(daily_frequency_students_params)
    daily_frequency_students_params[:students_attributes].select { |_, attribute| attribute['id'].blank? }
  end

  def update_daily_frequency_students_params(daily_frequency_record, daily_frequency_students_params)
    return if daily_frequency_record.new_record?

    not_persisted_daily_frequency_students =
      get_not_persisted_daily_frequency_students(daily_frequency_students_params)

    return if not_persisted_daily_frequency_students.blank?

    persisted_daily_frequency_students = daily_frequency_record.students

    not_persisted_daily_frequency_students.each_value do |value|
      persisted_daily_frequency_student =
        persisted_daily_frequency_students.find { |freq| freq.student_id.to_s == value['student_id'] }

      persisted_daily_frequency_student || next

      value.merge!(
        'id' => persisted_daily_frequency_student.id,
        'daily_frequency_id' => persisted_daily_frequency_student.daily_frequency_id
      )
    end
  end
end
