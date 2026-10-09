# Grupo com threads (cada uma na própria conexão) só enxerga dado commitado: sai da transação de teste
# do rspec-rails e limpa o que commitou. Marcar o grupo (describe/context) com `concurrent: true` —
# marcar o exemplo não funciona, porque `config.include` casa metadata de grupo.
#
# Sem a transação do rspec-rails, essa limpeza é a única que sobra: por isso ela é registrada aqui
# pelo próprio `concurrent: true`, e não pelos `type:` declarados abaixo. Fosse pelo `type:`, um grupo
# concorrente num arquivo que esquecesse de declará-lo commitaria tudo sem nada limpar depois.
#
# A estratégia é `deletion`, não `truncation`: no PostgreSQL a truncation emite
# `TRUNCATE ... RESTART IDENTITY` e zera todas as sequences, mudando os ids que os exemplos seguintes
# recebem. Spec que compara ids de tabelas diferentes passa a enxergar colisão e quebra longe daqui.
# `deletion` usa `DELETE FROM` dentro de `disable_referential_integrity`: limpa o dado commitado e
# deixa as sequences como o rollback transacional do resto da suíte deixa.
module ConcurrentExampleGroup
  extend ActiveSupport::Concern

  included { self.use_transactional_tests = false }
end

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }
  config.include ConcurrentExampleGroup, concurrent: true
  config.before(:each, concurrent: true) { DatabaseCleaner.strategy = :deletion }

  config.before(:each, type: :model) { DatabaseCleaner.start }
  config.before(:each, type: :form) { DatabaseCleaner.start }
  config.before(:each, type: :service) { DatabaseCleaner.start }
  config.before(:each, type: :controller) { DatabaseCleaner.start }
  config.before(:each, type: :query) { DatabaseCleaner.start }
  config.before(:each, type: :worker) { DatabaseCleaner.start }
  config.before(:each, type: :view) { DatabaseCleaner.start }

  # `before(:each)` de configuração roda na ordem de registro: este precisa vir depois dos
  # `DatabaseCleaner.start`. Sem isso, no spec que abre a conexão do tenant (`using_connection`) a
  # transação do rspec-rails não alcança o pool criado dentro do exemplo, e o usuário do `User.current`
  # fica commitado nesse banco.
  config.before(:each) { User.current = create(:user_with_user_role) }

  config.after(:each, type: :model) { DatabaseCleaner.clean }
  config.after(:each, type: :form) { DatabaseCleaner.clean }
  config.after(:each, type: :service) { DatabaseCleaner.clean }
  config.after(:each, type: :controller) { DatabaseCleaner.clean }
  config.after(:each, type: :query) { DatabaseCleaner.clean }
  config.after(:each, type: :worker) { DatabaseCleaner.clean }
  config.after(:each, type: :view) { DatabaseCleaner.clean }

  config.after(:each, concurrent: true) { DatabaseCleaner.clean_with(:deletion) }

  config.after(:example, type: :feature) { DatabaseCleaner.clean_with(:truncation) }
end
