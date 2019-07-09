require 'spec_helper'

RSpec.describe EntityDatabaseCreator, type: :service do
  it "creates a new database" do
    connection = double(:connection)
    database = "name"

    subject = EntityDatabaseCreator.new(database, connection)

    expect(connection).to receive(:create_database).with(database)
    expect(Kernel).to receive(:system).with("rake db:migrate")

    subject.create
  end
end
