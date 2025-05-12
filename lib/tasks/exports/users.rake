namespace :report do
  namespace :users do
    desc "Exporta dados de usuários ativos nos últimos N dias para CSV usando COPY. Ex: rake report:users:active_users[30]"
    task :active_users, [:days] => :environment do |t, args|
      args.with_defaults(days: '90')
      days = args[:days].to_i

      query = <<-SQL
        SELECT
            gu.id AS "ID",
            CONCAT(gu.first_name, ' ', gu.last_name) AS "Nome Completo",
            STRING_AGG(DISTINCT sr.name, ', ') AS "Nível de usuário",
            gu.email AS "Email"
        FROM
            users gu
        INNER JOIN user_roles sru ON
            sru.user_id = gu.id
        INNER JOIN roles sr ON
            sr.id = sru.role_id
        WHERE
            gu.current_sign_in_at >= NOW() - INTERVAL '90 days'
        GROUP BY
            gu.id,
            gu.email,
            gu.first_name,
            gu.last_name
      SQL

      copy_query = "COPY (#{query}) TO STDOUT WITH CSV HEADER ENCODING 'UTF8'"

      header_added = false

      File.open("active_users.csv", "w:UTF-8") do |file|
        Entity.find_each(batch_size: 100) do |entity|
          entity.using_connection do
            conn = ActiveRecord::Base.connection.raw_connection

            conn.copy_data(copy_query) do
              while (line = conn.get_copy_data)
                line = line.force_encoding('UTF-8')
                file.write(line)

                if !header_added
                  header_added = true
                end
              end
            end
          end
        end

        puts "Arquivo active_users.csv foi gerado com sucesso! (últimos #{days} dias)"
      end
    end
  end
end