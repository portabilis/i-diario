class AddOpinionToContents < ActiveRecord::Migration
  def change
    add_column :contents, :opinion, :text
  end
end
