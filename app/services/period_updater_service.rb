class PeriodUpdaterService
  attr_reader :classroom_id, :old_period, :new_period

  def self.update_period_dependents(classroom_id, old_period, new_period)
    new(classroom_id, old_period, new_period).update_period
  end

  def initialize(classroom_id, old_period, new_period)
    raise ArgumentError if classroom_id.blank? || old_period.blank? || new_period.blank?

    @classroom_id = Classroom.with_discarded.find(classroom_id)
    @old_period = old_period
    @new_period = new_period
  end

  def update_period
    DailyFrequency.where(classroom_id: classroom_id, period: old_period).each do |daily_frequency|
      begin
        daily_frequency.update(period: new_period)
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
end
