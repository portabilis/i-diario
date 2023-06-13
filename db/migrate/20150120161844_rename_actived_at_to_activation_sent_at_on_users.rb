class RenameActivedAtToActivationSentAtOnUsers < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :actived_at, :activation_sent_at
  end
end
