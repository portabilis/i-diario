class AddIndexToMvwFrequencyBySchoolClassroomTeachersByUnityIdAndFrequencyDate < ActiveRecord::Migration[5.0]
  def change
    add_index :mvw_frequency_by_school_classroom_teachers, [:unity_id, :frequency_date], name: 'index_mvw_frequency_on_unity_and_frequency_date'
  end
end
