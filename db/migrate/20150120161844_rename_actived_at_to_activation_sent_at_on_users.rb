class RenameActivedAtToActivationSentAtOnUsers < ActiveRecord::Migration
  def change
    rename_column :users, :actived_at, :activation_sent_at
  end
end
