class DropPreRegistrationsAndDependences < ActiveRecord::Migration
  def update
    drop_table :pre_registrations, { force: :cascade }
    drop_table :pre_registration_unities, { force: :cascade }
    drop_table :pre_registration_configs, { force: :cascade }
    drop_table :pre_registration_availabilities, { force: :cascade }
    drop_table :deficiencies_pre_registration, { force: :cascade }
  end
end
