# frozen_string_literal: true

class PhysicalFrequencyOnDate
  attr_reader :student_enrollment_ids, :date

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollment_ids = params.fetch(:student_enrollment_ids)
    @date = params.fetch(:date)
  end

  def call
    daily_physical_frequencies = DailyPhysicalFrequency.where(
      student_enrollment_id: student_enrollment_ids,
      frequency_date: date
    )

    physical_frequencies = {}

    daily_physical_frequencies.each do |physical_frequency|
      physical_frequencies[physical_frequency.student_enrollment_id] = physical_frequency.present
    end

    physical_frequencies
  end
end
