namespace :upgrade do
  namespace :versions do
    desc 'Upgrade to version 1.1.0'
    task '1_1_0': :environment do
      puts 'Upgrade task initialized.'

      Entity.active.each do |entity|
        entity.using_connection do
          synchronization = IeducarApiSynchronization.started.first

          if synchronization.present?
            synchronization.update(
              status: 'error',
              error_message: 'Sincronização cancelada pelo administrador.',
              full_error_message: ''
            )
          end

          StudentEnrollmentClassroom.all.delete_all

          configuration = IeducarApiConfiguration.current

          next unless configuration.persisted?

          full_synchronization = true
          configuration.start_synchronization(User.first, entity.id, full_synchronization)
        end
      end

      puts 'Upgrade task completed.'
    end
  end
end
