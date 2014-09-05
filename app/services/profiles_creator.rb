class ProfilesCreator
  attr_reader :status

  def setup
    profile_roles.each { |role| create_profile(role) }

    success
  end

  protected

  def create_profile(role)
    profile_repository.create!(role: role)
  end

  def success
    @status = I18n.t('services.profiles_creator.success')
  end

  def profile_roles
    ProfileRoles.list
  end

  def profile_repository
    Profile
  end
end
