class AdminSynchronizationsController < ApplicationController
  def index
    @entity_syncs = AdminSynchronization.new
  end
end
