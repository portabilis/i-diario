class NullifyInvalidCurrentUnityIdReferenceFromUsers < ActiveRecord::Migration[4.2]
  def change
    user_current_unity_ids = User.pluck(:current_unity_id).uniq.compact
    unity_ids = Unity.where(id: user_current_unity_ids).pluck(:id).uniq

    not_found = user_current_unity_ids - unity_ids

    User.where(current_unity_id: not_found).update_all(current_unity_id: nil) if not_found.present?
  end
end
