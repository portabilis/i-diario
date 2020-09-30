class SchoolCalendarEventBatchesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @event_batches = apply_scopes(SchoolCalendarEventBatch).ordered

    authorize @event_batches
  end
end
