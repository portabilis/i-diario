class DailyFrequencyStudentsBuilder

  def initialize(params)
    self.params = params
  end

  def build_all
    params.each do |record|
      next unless record[:student_id] && record[:daily_frequency_id]

      if daily_frequency_student = DailyFrequencyStudent.find_by(student_id: record[:student_id],
                                                                  daily_frequency_id: record[:daily_frequency_id])

        daily_frequency_student.update(present: record[:present])
      else
        DailyFrequencyStudent.create!(record)
      end
    end
  end

  protected

  attr_accessor :params
end
