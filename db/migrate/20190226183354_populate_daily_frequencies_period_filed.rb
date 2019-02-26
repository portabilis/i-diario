class PopulateDailyFrequenciesPeriodFiled < ActiveRecord::Migration
  def change
    Unity.includes(:classrooms).each do |unity|
      unity.classrooms.each do |classroom|
        DailyFrequency.where(classroom_id: classroom.id).update_all(period: classroom.period.to_i)
      end
    end
  end
end
