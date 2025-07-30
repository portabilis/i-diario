class DailyFrequencyPresenter < BasePresenter
  def initialize(student:, date:, daily_frequency:, response_data:, physical_frequencies:)
    @student = student
    @date = date
    @daily_frequency = daily_frequency
    @response_data = response_data
    @physical_frequencies = physical_frequencies
  end

  def default_presence
    is_new_record = !@daily_frequency.persisted?

    default_presence = true

    if is_new_record && !ignored? && any_physical_presence_for_this_date?
      physical_presence_status = @physical_frequencies.dig(@student[:student_enrollment_id], @date)
      default_presence = !physical_presence_status.nil?
    end

    default_presence
  end

  def ignored?
    @response_data[:response_class].present?
  end

  private

  def any_physical_presence_for_this_date?
    @physical_frequencies.values.any? { |date_hash| date_hash.key?(@date) }
  end
end
