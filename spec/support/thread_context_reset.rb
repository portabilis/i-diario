# Isola o contexto thread-local entre exemplos: sem isso, um exemplo que
# define Entity.current/User.current/origin_type vazaria o valor para os
# seguintes (a suíte roda tudo na mesma thread).
RSpec.configure do |config|
  config.after do
    Entity.current = nil
    User.current = nil
    Thread.current[:origin_type] = nil
  end
end
