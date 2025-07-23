# Monitoramento com Honeybadger

Este projeto possui suporte integrado ao [Honeybadger](https://www.honeybadger.io), uma ferramenta de monitoramento de erros para aplicações Ruby on Rails.

## Visão geral

O Honeybadger permite que erros e exceções em produção sejam monitorados automaticamente, com notificações detalhadas e breadcrumbs de contexto. A integração já está preparada no código-fonte — basta ativar a configuração com a sua API Key.

## Como ativar o monitoramento

1. Acesse [https://app.honeybadger.io](https://app.honeybadger.io)
2. Crie uma conta ou entre com sua conta existente.
3. Crie um novo projeto (Project).
4. No painel do projeto, copie a **API Key** disponível.
5. Copie o arquivo de configuração de exemplo:

   ```bash
   cp config/honeybadger.sample.yml config/honeybadger.yml
   ```

6. Edite o arquivo `config/honeybadger.yml` e substitua o valor da chave `api_key` pela sua API Key:

   ```yaml
   # config/honeybadger.yml
   ---
   production:
     api_key: 'SUA_API_KEY_AQUI'
     breadcrumbs:
       enabled: true
   ```

> A configuração será carregada automaticamente quando o ambiente estiver definido como `RAILS_ENV=production`.

## Exemplo de log no console

Quando corretamente configurado, os erros serão reportados automaticamente ao painel do Honeybadger. Você também poderá ver logs como:

```bash
[Honeybadger] Reporting error id=abc123 level=1 pid=12345
```

## Arquivo incluído

Este repositório inclui:

- `config/honeybadger.sample.yml`: Arquivo de exemplo para facilitar a ativação.

## Saiba mais

- Documentação oficial: [https://docs.honeybadger.io](https://docs.honeybadger.io)
- Configurações avançadas: [https://docs.honeybadger.io/lib/ruby/reference/configuration.html](https://docs.honeybadger.io/lib/ruby/reference/configuration.html)