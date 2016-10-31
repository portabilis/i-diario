class InsertDefaultValueToTermsDictionaries < ActiveRecord::Migration
  def change
    execute <<-SQL
      INSERT INTO terms_dictionaries values(1, '.', CURRENT_DATE, CURRENT_DATE);
    SQL
  end
end
