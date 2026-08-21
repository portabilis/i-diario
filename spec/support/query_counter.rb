module QueryCounter
  IGNORED_QUERIES = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)/i

  def count_queries
    count = 0

    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] == 'SCHEMA' || payload[:sql].to_s =~ IGNORED_QUERIES

      count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { yield }

    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
