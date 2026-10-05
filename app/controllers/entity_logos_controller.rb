# Serve o brasão da rede por uma URL estável, com a versão do arquivo em `v`.
# O arquivo no storage só é acessível por URL assinada, que muda a cada página e
# impede o cache do navegador; aqui a imagem sai do Rails.cache e fica em cache
# no navegador enquanto a versão pedida for a atual.
#
# Herda de ActionController::Base porque o brasão aparece também no login e na
# tela de rede desativada, e os filtros do ApplicationController (autenticação,
# troca de senha, papel atual) redirecionariam a requisição da imagem.
class EntityLogosController < ActionController::Base
  around_action :use_entity_connection

  def show
    configuration = EntityConfiguration.first
    logo = configuration&.cached_logo_data(:web)

    return head :not_found unless logo

    expires_in 1.year, public: true if params[:v] == configuration.logo.identifier

    send_data logo[:data], type: logo[:content_type], disposition: :inline
  end

  private

  def use_entity_connection(&block)
    entity = Entity.find_by(domain: request.host)

    return head :not_found unless entity

    entity.using_connection(&block)
  end
end
