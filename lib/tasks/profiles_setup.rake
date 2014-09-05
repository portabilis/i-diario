namespace :profiles do
  desc "Profiles Setup"
  task setup: :environment do
    creator = ProfilesCreator.new

    creator.setup

    puts creator.status
  end
end
