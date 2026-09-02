# Grupo com threads (cada uma na própria conexão) só enxerga dado commitado: sai da transação de teste
# do rspec-rails e limpa por truncation. Marcar o grupo (describe/context) com `concurrent: true` —
# marcar o exemplo não funciona, porque `config.include` casa metadata de grupo.
#
# Sem a transação do rspec-rails, a truncation é a única limpeza que sobra: por isso ela é registrada
# aqui pelo próprio `concurrent: true`, e não pelos `type:` declarados abaixo. Fosse pelo `type:`, um
# grupo concorrente num arquivo que esquecesse de declará-lo commitaria tudo sem nada limpar depois.
module ConcurrentExampleGroup
  extend ActiveSupport::Concern

  included { self.use_transactional_tests = false }
end

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  config.before(:each) { User.current = create(:user_with_user_role) }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }
  config.include ConcurrentExampleGroup, concurrent: true
  config.before(:each, concurrent: true) { DatabaseCleaner.strategy = :truncation }

  config.before(:each, type: :model) { DatabaseCleaner.start }
  config.before(:each, type: :form) { DatabaseCleaner.start }
  config.before(:each, type: :service) { DatabaseCleaner.start }
  config.before(:each, type: :controller) { DatabaseCleaner.start }
  config.before(:each, type: :query) { DatabaseCleaner.start }
  config.before(:each, type: :worker) { DatabaseCleaner.start }

  config.after(:each, type: :model) { DatabaseCleaner.clean }
  config.after(:each, type: :form) { DatabaseCleaner.clean }
  config.after(:each, type: :service) { DatabaseCleaner.clean }
  config.after(:each, type: :controller) { DatabaseCleaner.clean }
  config.after(:each, type: :query) { DatabaseCleaner.clean }
  config.after(:each, type: :worker) { DatabaseCleaner.clean }

  config.after(:each, concurrent: true) { DatabaseCleaner.clean_with(:truncation) }

  config.after(:example, type: :feature) { DatabaseCleaner.clean_with(:truncation) }
end
