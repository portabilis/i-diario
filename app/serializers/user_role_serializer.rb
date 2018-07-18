class UserRoleSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :role_id, :unity_id, :can_change_school_year?

  has_one :role
end
