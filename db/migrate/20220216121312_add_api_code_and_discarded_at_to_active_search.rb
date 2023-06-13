class AddApiCodeAndDiscardedAtToActiveSearch < ActiveRecord::Migration[4.2]
  def change
    add_column :active_searches, :api_code, :string
    add_column :active_searches, :discarded_at, :datetime
  end
end
