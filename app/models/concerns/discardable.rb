module Discardable
  extend ActiveSupport::Concern

  include Discard::Model

  def discard_or_undiscard(discardable)
    discard if kept? && discardable
    undiscard if discarded? && !discardable
  end

  def kept?
    !discarded?
  end
end
