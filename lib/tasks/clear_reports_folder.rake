desc "Erases all the content of the public/relatorios folder"
task clear_reports: :environment do
  dir_path ="#{Rails.root}/public/relatorios/"
  Dir.foreach(dir_path) do |f|
    fn = File.join(dir_path, f)
    File.delete(fn) if f != '.' && f != '..'
  end
end
