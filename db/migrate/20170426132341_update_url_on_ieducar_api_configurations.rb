class UpdateUrlOnIeducarApiConfigurations < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE ieducar_api_configurations SET url = replace(url, 'http://', 'https://');
    SQL
  end
end
