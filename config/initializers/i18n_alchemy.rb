ActiveSupport.on_load(:active_record) do
  include I18n::Alchemy
end
