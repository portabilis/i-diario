namespace :entity do
  desc "Entity Setup"
  task setup: :environment do
    creator = EntityCreator.new(ENV)

    creator.setup

    puts creator.status
  end

  desc "Enable Entity"
  task enable: :environment do
    entity_status_manager = EntityStatusManager.new(ENV)

    entity_status_manager.enable

    puts entity_status_manager.status
  end

  desc "Disable Entity"
  task disable: :environment do
    entity_status_manager = EntityStatusManager.new(ENV)

    entity_status_manager.disable

    puts entity_status_manager.status
  end

  namespace :admin do
    desc "Create Admin User"
    task create: :environment do
      admin_user_creator = AdminUserCreator.new(ENV)

      admin_user_creator.create

      puts admin_user_creator.status
    end
  end
end
