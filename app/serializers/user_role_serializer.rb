class UserRoleSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :role_id, :unity_id

  has_one :role
end
