class RemoveUnneededIndexAvaliationExemptionsOnAvaliationId < ActiveRecord::Migration[4.2]
  def up
    remove_index :avaliation_exemptions, name: "index_avaliation_exemptions_on_avaliation_id"
  end

  def down
    execute %{
      CREATE INDEX index_avaliation_exemptions_on_avaliation_id ON public.avaliation_exemptions USING btree (avaliation_id);
    }
  end
end
