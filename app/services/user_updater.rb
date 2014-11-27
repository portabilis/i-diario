class UserUpdater
  def self.update!(*attributes)
    new(*attributes).update!
  end

  def initialize(user, entity)
    self.user = user
    self.entity = entity
  end

  def update!
    if user.actived? && user.actived_at.blank?
      UserMailer.notify_actived(user, entity).deliver
      user.actived!
    end
  end

  protected

  attr_accessor :user, :entity
end
