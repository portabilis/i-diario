class NullifyInvalidCurrentUnityIdReferenceFromUsers < ActiveRecord::Migration
  def change
    User.all.each do |user|
      current_unity_id = user.current_unity_id

      if current_unity_id.present? && !Unity.find_by(id: current_unity_id)
        user.update(current_unity_id: nil)
      end
    end
  end
end
