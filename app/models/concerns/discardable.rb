module Discardable
  extend ActiveSupport::Concern

  include Discard::Model

  def discard_or_undiscard(discardable)
    with_lock do
      discard if kept? && discardable
      undiscard if discarded? && !discardable
    end
  end

  def kept?
    !discarded?
  end
end
