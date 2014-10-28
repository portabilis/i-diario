#encoding: utf-8
unless Entity.exists?
  Entity.create!(
    name: "Prefeitura",
    domain: "prefeitura.educacao.local",
    config: {
      database: "novo_educacao_development"
    }
  )
end

unless User.exists?
  User.create!(
    email: 'admin@example.com',
    password: '12345678',
    password_confirmation: '12345678',
    first_name: 'Usuario',
    last_name: 'Administrador',
    login: 'admin',
    phone: '(11) 9988-7766',
    cpf: '639.290.118-32',
    authorize_email_and_sms: false
  )
end

***REMOVED***.create(description: 'Cereais e derivados')
***REMOVED***.create(description: 'Verduras, hortaliças e derivados')
***REMOVED***.create(description: 'Frutas e derivados')
***REMOVED***.create(description: 'Gorduras e óleos')
***REMOVED***.create(description: 'Pescados e frutos do mar')
***REMOVED***.create(description: 'Carnes e derivados')
***REMOVED***.create(description: 'Leite e derivados')
***REMOVED***.create(description: 'Bebidas (alcoólicas e não alcoólicas)')
***REMOVED***.create(description: 'Ovos e derivados')
***REMOVED***.create(description: 'Produtos açucarados')
***REMOVED***.create(description: 'Miscelâneas')
***REMOVED***.create(description: 'Outros ***REMOVED*** industrializados')
***REMOVED***.create(description: '***REMOVED*** preparados')
***REMOVED***.create(description: 'Leguminosas e derivados')
***REMOVED***.create(description: 'Nozes e sementes')

if ***REMOVED***.count < 1
  ActiveRecord::Base.connection.execute File.read("#{Rails.root}/db/seeds/***REMOVED***.sql")
end
