module Portabilis
  class FormBuilder < SimpleForm::FormBuilder
    map_type :decimal, :float,                   :to => Portabilis::Inputs::DecimalInput
    map_type :date,                              :to => Portabilis::Inputs::DateInput
    map_type :string, :email, :tel, :integer,    :to => Portabilis::Inputs::StringInput
    map_type :password,                          :to => Portabilis::Inputs::PasswordInput
    map_type :radio_buttons,                     :to => Portabilis::Inputs::RadioButtons
    map_type :text,                              :to => Portabilis::Inputs::TextInput
    map_type :select,                            :to => Portabilis::Inputs::CollectionSelectInput
  end
end
