namespace :users do
  namespace :by_csv do
    desc 'Create users by csv'
    task create: :environment do
      user_creator = UserByCsv.new(ENV)

      user_creator.create

      puts user_creator.status
    end
  end
end
