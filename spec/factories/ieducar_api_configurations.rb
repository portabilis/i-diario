FactoryGirl.define do
  factory :ieducar_api_configuration do
    url 'http://test.ieducar.com.br'
    token '8IOwGIjiHvbeTklgwo10yVLgwDhhvs'
    secret_token '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC'
    unity_code 1

    # Fora do atributo padrão de propósito: specs de controller da API v2 montam o header `token`
    # a partir desta factory, e um valor em branco ali muda o caminho de autenticação exercitado.
    # Use a trait apenas onde o token realmente importa.
    trait :with_api_security_token do
      api_security_token 'nSDpPZg2DiYyOMPTaWTBoAcCVKlDdE'
    end
  end
end
