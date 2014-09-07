class EntityDatabaseCreator
  def self.create(database)
    new(database).create
  end

  def initialize(database, connection = ActiveRecord::Base.connection)
    self.database = database
    self.connection = connection
  end

  def create
    connection.create_database database

    run_migrations
  end

  protected

  attr_accessor :database, :connection

  def run_migrations
    Kernel.system("rake db:migrate")
  end
end
