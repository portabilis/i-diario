class SystemNotificationSerializer < ActiveModel::Serializer
  include ActionView::Helpers::DateHelper
  attributes :title, :description, :link, :distance_in_words

  def link
    SystemNotificationRouter.path(object)
  end

  def distance_in_words
    distance_of_time_in_words_to_now object.created_at
  end
end
