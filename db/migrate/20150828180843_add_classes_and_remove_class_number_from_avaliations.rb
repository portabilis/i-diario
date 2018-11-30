class AddClassesAndRemoveClassNumberFromAvaliations < ActiveRecord::Migration
  def change
    add_column :avaliations, :classes, :integer, array: true, default: []

    execute <<-SQL
      UPDATE avaliations SET classes = array(SELECT a.class_number FROM avaliations a WHERE a.id = avaliations.id);
    SQL

    remove_column :avaliations, :class_number
  end
end