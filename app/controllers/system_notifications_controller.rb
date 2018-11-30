class SystemNotificationsController < ApplicationController
  respond_to :json, only: :index

  def read_all
    current_user.read_notifications!

    render json: :ok
  end

  def index
    render(
      json: {
        system_notifications: ActiveModel::ArraySerializer.new(current_user.system_notifications.limit(10).ordered, each_serializer: SystemNotificationSerializer),
        unread_notifications_count: current_user.unread_notifications.count
      }
    )
  end
end
