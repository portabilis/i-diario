module RoleHelper
  def access_level_tags(role_permission)
    tags = ""
    AccessLevel.list.each do |access_level|
      tags += " data-level-"+access_level if role_permission.access_level_has_feature?(access_level)
    end
    tags
  end
end