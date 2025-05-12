module FixtureLoad
  def json_file_fixture(file_path)
    JSON.parse(File.read(Rails.root.to_s + file_path), symbolize_names: true)
  end
end
