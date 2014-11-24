class ProfilesController < ApplicationController
  def index
    @profiles = Profile.all.order(:id)
  end

  def update
    updater = ProfileUpdater.new(params)

    updater.update

    head updater.status, :content_type => 'text/html'
  end

  def history
    @profile = Profile
  end
end
