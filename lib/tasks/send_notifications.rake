namespace :send_notification do
  desc 'Send absence notification'
  task absences: :environment do
    Entity.active.each do |entity|
      entity.using_connection do
        general_configuration = GeneralConfiguration.current

        next unless general_configuration.notify_consecutive_or_alternate_absences

        InfrequencyTrackingNotifierWorker.perform_in(1.second, entity.id)
      end
    end
  end
end
