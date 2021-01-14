class AddUniqueIndexOnSchoolTermTypes < ActiveRecord::Migration
  def change
    add_index :school_term_types, :description, unique: true
  end
end
