module DatabaseRewinder
  extend self

  def truncate
    ActiveRecord::Base.connection.execute "TRUNCATE #{tables.join(", ")} RESTART IDENTITY CASCADE" if tables.any?
  end

  def tables
    (ActiveRecord::Base.connection.tables - ["schema_migrations"]).sort
  end
end

RSpec.configure do |config|
  config.before :suite do
    DatabaseRewinder.truncate
  end

  config.after :example do
    DatabaseRewinder.truncate
  end
end
