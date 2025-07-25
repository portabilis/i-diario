# Debug de Requisições da API i-Educar

## Como ativar

Para ativar o log detalhado de todas as requisições feitas para a API do i-Educar, configure a variável `debug_ieducar_api` no arquivo `config/secrets.yml`:

```yaml
development:
  # ... outras configurações ...
  debug_ieducar_api: true
```

## O que é logado

Quando o debug está ativo, as seguintes informações são registradas no log:

### Requisição
- Método HTTP (GET/POST)
- Endpoint completo
- Parâmetros da requisição
- Payload (para requisições POST)
- URL completa com query string

### Resposta
- Resposta raw (truncada em 1000 caracteres)
- Resposta parseada como JSON
- Mensagens de erro da API
- Status de erro e exceções

### Erros
- Tipo de erro e mensagem
- Stack trace (primeiras 5 linhas)
- Erros de rede específicos

## Formato do log

Todos os logs são prefixados com `[DEBUG_IEDUCAR_API]` para facilitar a filtragem:

```
[DEBUG_IEDUCAR_API] Starting request to i-Educar API
[DEBUG_IEDUCAR_API] Method: GET
[DEBUG_IEDUCAR_API] Endpoint: https://api.ieducar.com.br/module/Api/Aluno
[DEBUG_IEDUCAR_API] Request params: {"access_key":"xxx","secret_key":"yyy","instituicao_id":1}
[DEBUG_IEDUCAR_API] Full URL: https://api.ieducar.com.br/module/Api/Aluno?access_key=xxx&secret_key=yyy
```

## Visualizar logs

Para visualizar apenas os logs da API:

```bash
# No container Docker
docker-compose exec puma tail -f log/development.log | grep DEBUG_IEDUCAR_API

# Ou direto no arquivo
grep DEBUG_IEDUCAR_API log/development.log
```

## Importante

- **Não ative em produção**: O debug pode expor informações sensíveis nos logs
- **Performance**: O log detalhado pode impactar a performance em sincronizações grandes
- **Tamanho dos logs**: Logs podem crescer rapidamente durante sincronizações completas