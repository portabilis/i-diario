module Portabilis
  class FormBuilder < SimpleForm::FormBuilder
    map_type :autocomplete,                      :to => Portabilis::Inputs::AutocompleteInput
    map_type :decimal, :float,                   :to => Portabilis::Inputs::DecimalInput
    map_type :date,                              :to => Portabilis::Inputs::DateInput
    map_type :datetime,                              :to => Portabilis::Inputs::DatetimeInput
    map_type :boolean,                           :to => Portabilis::Inputs::BooleanInput
    map_type :string, :email, :integer,          :to => Portabilis::Inputs::StringInput
    map_type :tel,                               :to => Portabilis::Inputs::TelInput
    map_type :password,                          :to => Portabilis::Inputs::PasswordInput
    map_type :radio_buttons,                     :to => Portabilis::Inputs::RadioButtons
    map_type :text,                              :to => Portabilis::Inputs::TextInput
    map_type :select,                            :to => Portabilis::Inputs::CollectionSelectInput
  end
end
