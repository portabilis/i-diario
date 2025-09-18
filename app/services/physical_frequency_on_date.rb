# frozen_string_literal: true

class PhysicalFrequencyOnDate
    attr_reader :student_enrollment_ids, :start_date, :end_date

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollment_ids = params.fetch(:student_enrollment_ids)
    @start_date = params.fetch(:start_date)
    @end_date = params.fetch(:end_date, @start_date)
  end

  def call
    daily_physical_frequencies = DailyPhysicalFrequency.where(
      student_enrollment_id: student_enrollment_ids,
      frequency_date: start_date..end_date
    )

    physical_frequencies = {}

    daily_physical_frequencies.each do |physical_frequency|
      physical_frequencies[physical_frequency.student_enrollment_id] ||= {}
      physical_frequencies[physical_frequency.student_enrollment_id][physical_frequency.frequency_date] = physical_frequency.present
    end

    physical_frequencies
  end
end
