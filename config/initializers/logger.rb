unless Rails.env.test? || Rails.env.development?
  GELF::Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer
end
