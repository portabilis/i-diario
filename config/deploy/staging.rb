# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

if ENV['to'] == "staging"
  set :branch, "development"
  set :domain, 'ncloudtest1.portabilis.com.br'
  set :deploy_to, '/var/www/novo-educacao'
end
