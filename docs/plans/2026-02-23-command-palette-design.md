# Command Palette (Ctrl+K) - Design Document

## Overview

Sistema de navegação rápida tipo CMD+K para o i-Diário. O usuário pressiona Ctrl+K (Windows/Linux) ou Cmd+K (Mac), um modal overlay aparece com campo de busca, lista todos os itens de menu disponíveis e permite navegar digitando e selecionando.

## Decisões de Design

- **Escopo:** Apenas navegação entre páginas do menu (sem ações rápidas)
- **Dados:** Extraídos do DOM do menu lateral já renderizado (zero backend)
- **Permissões:** Respeitadas automaticamente (só existe no DOM o que o usuário pode ver)
- **Busca:** Fuzzy search simples (normaliza acentos, match por palavras em qualquer ordem)
- **Atalho:** Ctrl+K (Windows/Linux), Cmd+K (Mac)
- **Implementação:** Vanilla JS, arquivo único, self-contained

## Arquitetura

Um único arquivo: `app/assets/javascripts/views/layouts/command_palette.js`

### Extração do DOM

```
#left-panel nav > ul > li          → menu primeiro nível
  > a > span.menu-item-parent      → título
  > a[href]                        → link
  > ul > li > a                    → submenus (título = "Pai > Filho")
```

### Modal UI

- Overlay escuro semi-transparente
- Modal centralizado, ~500px largura, máx 60vh altura
- Input de busca com placeholder "Navegar para..."
- Lista de resultados com ícones Font Awesome do menu
- Footer com dicas de atalho (↑↓ navegar, ⏎ abrir, esc fechar)

### Interações

| Ação | Comportamento |
|------|---------------|
| Ctrl+K / Cmd+K | Abre/fecha modal (toggle) |
| Digitar | Filtra lista em tempo real |
| ↑ / ↓ | Move seleção entre resultados |
| Enter | Navega para item selecionado |
| Esc | Fecha modal |
| Clique no backdrop | Fecha modal |
| Clique num item | Navega para ele |

### Edge Cases

- Menu colapsado: DOM ainda presente, extração funciona
- Foco em input/textarea: Ctrl+K NÃO abre modal (não atrapalha digitação)
- Sem resultados: mensagem "Nenhum resultado encontrado"
- Acentos: normaliza para busca sem acentos

### Acessibilidade

- role="dialog", aria-modal="true"
- role="listbox" na lista
- aria-selected no item ativo
- Focus trap dentro do modal
