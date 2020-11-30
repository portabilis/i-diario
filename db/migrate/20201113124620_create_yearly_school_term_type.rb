class CreateYearlySchoolTermType < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    SchoolTermType.create!(description: 'Anual', steps_number: 1)
  end
end
