class PopulateDailyFrequenciesPeriodFiled < ActiveRecord::Migration[4.2]
  def change
    Unity.includes(:classrooms).each do |unity|
      unity.classrooms.each do |classroom|
        DailyFrequency.where(classroom_id: classroom.id)
                      .where(period: nil)
                      .update_all(period: classroom.period.to_i)
      end
    end
  end
end
