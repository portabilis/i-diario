class UpdateGeneralConfigurationInfo < ActiveRecord::Migration
  def change
    general_configuration = GeneralConfiguration.current

    general_configuration.copyright_name = 'Portabilis'
    general_configuration.support_freshdesk = 'https://portabilis.freshdesk.com'
    general_configuration.support_url = 'http://portabilis.com.br'

    general_configuration.save(validate: false)
  end
end
