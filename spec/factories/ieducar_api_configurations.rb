FactoryGirl.define do
  factory :ieducar_api_configuration do
    url 'http://test.ieducar.com.br'
    token '8IOwGIjiHvbeTklgwo10yVLgwDhhvs'
    secret_token '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC'
    unity_code 1

    # Fora do atributo padrão de propósito: specs de controller da API v2 montam o header `token`
    # a partir desta factory, e em `test` o header vazio é o que faz o
    # `ApplicationController#allowed_api_header?` liberar a requisição (`nil == nil`). Preenchê-lo
    # aqui tira esses specs desse caminho e eles passam a receber 401.
    trait :with_api_security_token do
      api_security_token 'nSDpPZg2DiYyOMPTaWTBoAcCVKlDdE'
    end
  end
end
