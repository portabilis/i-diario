class SystemNotificationSerializer < ActiveModel::Serializer
  include ActionView::Helpers::DateHelper
  attributes :title, :description, :link, :distance_in_words, :open_link_in_new_tab

  def link
    SystemNotificationRouter.path(object)
  end

  def distance_in_words
    distance_of_time_in_words_to_now object.created_at
  end

  def open_link_in_new_tab
    object.open_link_in_new_tab?
  end
end
