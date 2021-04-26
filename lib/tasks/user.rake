namespace :user do
  namespace :by_csv do
    desc 'Create users by csv'
    task create: :environment do
      user_creator = UserByCsv.new(ENV)

      user_creator.create

      puts user_creator.status
    end
  end
  namespace :reset_password do
    desc 'Reset password'
    task reset: :environment do
      user_updater = ResetPassword.new(ENV)

      user_updater.update

      puts user_updater.status
    end
  end
end
