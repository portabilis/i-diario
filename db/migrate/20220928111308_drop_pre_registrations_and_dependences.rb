class DropPreRegistrationsAndDependences < ActiveRecord::Migration
  def change
    drop_table :deficiencies_pre_registrations
    drop_table :pre_registration_availabilities
    drop_table :pre_registration_unities
    drop_table :pre_registration_configs
    drop_table :pre_registrations
  end
end
