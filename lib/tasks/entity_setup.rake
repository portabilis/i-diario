namespace :entity do
  desc "Entity Setup"
  task setup: :environment do
    creator = EntityCreator.new(ENV)

    creator.setup

    puts creator.status
  end
end
