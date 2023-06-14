class CreateFunctionSetTransferDateInTransferNotes < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION set_transfer_date_in_transfer_notes()
      RETURNS trigger AS $BODY$
      BEGIN
        new.transfer_date := new.recorded_at;
        RETURN new;
      END;
      $BODY$ LANGUAGE plpgsql;
    SQL
  end
end
