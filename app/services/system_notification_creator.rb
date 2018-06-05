class SystemNotificationCreator
  def self.create!(attributes)
    new(attributes).create!
  end

  def initialize(attributes)
    self.attributes = attributes
  end

  def create!
    users = attributes.delete(:users)
    attributes[:generic] ||= false

    raise "Users can't be blank" if users.blank?
    raise "Source can't be blank" if attributes[:source].blank? && !attributes[:generic]

    ActiveRecord::Base.transaction do
      notification = SystemNotification.create!(attributes)

      users.each do |user|
        notification.targets.find_or_create_by!(user: user)
      end

      notification
    end
  end

  protected

  attr_accessor :attributes
end
