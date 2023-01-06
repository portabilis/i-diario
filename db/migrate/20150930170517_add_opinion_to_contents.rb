class AddOpinionToContents < ActiveRecord::Migration[4.2]
  def change
    add_column :contents, :opinion, :text
  end
end
