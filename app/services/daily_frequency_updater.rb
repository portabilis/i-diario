class DailyFrequencyUpdater
  def update(params)
    return if params.blank?

    params = get_valid_params(params)
    daily_frequency_students_to_create = []

    ActiveRecord::Base.transaction do
      params.group_by { |param| param[:daily_frequency_id] }.each do |daily_frequency_id, daily_frequency_students_params|
        daily_frequency_students = DailyFrequencyStudent.where(daily_frequency_id: daily_frequency_id)
          .includes(:daily_frequency, :student)

        daily_frequency_students_params.each do |param|
          daily_frequency_students_to_create << param if daily_frequency_students.none? { |student| student.student_id == param[:student_id].to_i }
        end

        daily_frequency_students.each do |student|
          student_param = params.find { |param| param[:daily_frequency_id].to_i.eql?(student.daily_frequency_id) && param[:student_id].to_i.eql?(student.student_id) }
          if student_param.present?
            student.update_attributes(present: student_param[:present], dependence: student_param[:dependence])
            student.update if student.changed?
          else
            student.destroy
          end
        end
      end

      DailyFrequencyStudent.bulk_insert(values: daily_frequency_students_to_create) if daily_frequency_students_to_create.any?
    end
  end

  private

  def get_valid_params(params)
    params.select { |param| param[:student_id ] && param[:daily_frequency_id] }
  end
end
