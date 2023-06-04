class RemoveUnneededIndexDailyFrequencyStudentsOnDailyFrequencyId < ActiveRecord::Migration[4.2]
  def up
    remove_index :daily_frequency_students, name: "index_daily_frequency_students_on_daily_frequency_id"
  end

  def down
    execute %{
      CREATE INDEX index_daily_frequency_students_on_daily_frequency_id ON public.daily_frequency_students USING btree (daily_frequency_id);
    }
  end
end
