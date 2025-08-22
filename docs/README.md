# Documentação do i-Diário

Esta pasta contém documentação técnica detalhada sobre os principais sistemas do i-Diário.

## Documentos Disponíveis

### [Sistema de Permissões](./sistema-de-permissoes.md)
Explica como funciona o controle de acesso e permissões no i-Diário:
- Arquitetura de Features e Roles
- Implementação com Pundit
- Como adicionar novas permissões
- Gerenciamento de permissões
- Troubleshooting

### [Sistema de Sincronização](./sistema-de-sincronizacao.md)
Detalha o processo de sincronização com o i-Educar:
- Tipos de sincronização (incremental e completa)
- Arquitetura de Workers e Synchronizers
- Ordem de sincronização e dependências
- Configuração e monitoramento
- Tratamento de erros

## Como Contribuir

Para adicionar nova documentação:

1. Crie um arquivo `.md` descritivo
2. Use formatação Markdown clara
3. Inclua exemplos de código quando relevante
4. Adicione diagramas para conceitos complexos
5. Atualize este README com link para o novo documento

## Convenções

- **Títulos**: Use `#` para título principal, `##` para seções
- **Código**: Use blocos de código com syntax highlighting
- **Diagramas**: Use Mermaid para fluxogramas e diagramas
- **Exemplos**: Sempre que possível, inclua exemplos práticos

### Visualizando Diagramas Mermaid

Os diagramas Mermaid são renderizados automaticamente no GitHub. Para visualizar localmente:

1. Use extensões do VS Code como "Markdown Preview Mermaid Support"
2. Ou visualize online em [mermaid.live](https://mermaid.live)

## Manutenção

Esta documentação deve ser atualizada sempre que:
- Novas funcionalidades forem adicionadas
- Arquitetura sofrer mudanças significativas
- Processos importantes forem modificados
- Bugs recorrentes precisarem de documentação

---
*Última atualização: Janeiro 2025*