class NullUserRole < UserRole
  def role
    Role.new
  end
end
