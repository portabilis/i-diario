class AddIndexClassroomsOnYearUnityIdAndDiscardedAt < ActiveRecord::Migration
  def up
    execute('CREATE INDEX index_classrooms_on_year_unity_id_and_discarded_at
                       ON public.classrooms USING btree (year, unity_id) WHERE (discarded_at IS NULL)')
  end

  def down
    execute('DROP INDEX index_classrooms_on_year_unity_id_and_discarded_at')
  end
end
