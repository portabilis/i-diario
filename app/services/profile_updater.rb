class ProfileUpdater
  attr_reader :id, :permission, :value, :status

  def initialize(params)
    @id = params[:id]
    @permission = params[:permission]
    @value = params[:value]
  end

  def update
    (has_params? && profile.update_attribute(permission, value)) ? success : error
  end

  protected

  def has_params?
    id && permission && !value.nil?
  end

  def success
    @status = 200
  end

  def error
    @status = 503
  end

  def profile
    profile_repository.find(id)
  end

  def profile_repository
    Profile
  end
end
