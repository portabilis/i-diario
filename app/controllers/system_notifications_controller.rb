class SystemNotificationsController < ApplicationController
  respond_to :json, only: :index

  def read_all
    current_user.read_***REMOVED***!

    render json: :ok
  end

  def index
    render(
      json: {
        system_***REMOVED***: ActiveModel::ArraySerializer.new(current_user.system_***REMOVED***.limit(10).ordered, each_serializer: SystemNotificationSerializer),
        unread_***REMOVED***_count: current_user.unread_***REMOVED***.count
      }
    )
  end
end
