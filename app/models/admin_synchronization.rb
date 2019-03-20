class AdminSynchronization
  class << self
    def dump
      $REDIS_DB.set('AdminSynchronizations', Marshal.dump(mount))
      $REDIS_DB.set('AdminSynchronizations#updated_at', Time.current)
    end

    private

    def mount
      started = []
      finished = []

      Entity.active.each do |entity|
        entity.using_connection do
          started << mount_started(entity)
          finished << mount_finished(entity)
        end
      end

      (started + finished).compact.group_by { |_, v| v[:status] }
    end

    def mount_finished(entity)
      if last_sync = IeducarApiSynchronization.where(status: [:completed, :error]).last
        [
          entity.name,
          {
            finished_sync: sync_struct(last_sync),
            status: last_sync.status,
            average_time: IeducarApiSynchronization.average_time
          }
        ]
      end
    end

    def mount_started(entity)
      if started = IeducarApiSynchronization.started.first
        [
          entity.name,
          {
            started_sync: sync_struct(started),
            status: started.status,
            average_time: IeducarApiSynchronization.average_time
          }
        ]
      end
    end

    def sync_struct(sync)
      return unless sync

      OpenStruct.new(
        started_at: sync.started_at,
        ended_at: sync.ended_at,
        time_running: sync.time_running,
        status: sync.status,
        done_percentage: sync.done_percentage,
        'started?': sync.started?,
        'error?': sync.error?,
        error_message: sync.error_message,
        full_error_message: sync.full_error_message
      )
    end
  end

  def updated_at
    $REDIS_DB.get('AdminSynchronizations#updated_at')
  end

  def started
    entity_syncs['started'] || []
  end

  def completed
    entity_syncs['completed'] || []
  end

  def error
    entity_syncs['error'] || []
  end

  private

  def entity_syncs
    @entity_syncs ||= Marshal.load($REDIS_DB.get('AdminSynchronizations')) || {}
  rescue StandardError => error
    Honeybadger.notify(error)

    {}
  end

end
