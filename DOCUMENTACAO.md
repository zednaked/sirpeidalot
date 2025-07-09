# Documentação do Projeto: Sistema de Jogo

Este documento fornece as instruções para configurar e usar o sistema de jogo, incluindo combate, interface e deploy.

## 1. Configuração da Cena Principal (`main.tscn`)

A cena principal precisa de uma estrutura específica e referências de nós configuradas corretamente.

### 1.1. Estrutura de Nós Essencial

-   **main (Node2D)**: Nó raiz com o script `dungeon_generator.gd`.
    -   **Player (Jogador.tscn)**: Instância da cena do jogador.
    -   **Node (Node)**: Contêiner para todos os inimigos.
        -   **esqueleto (esqueleto.tscn)**: Instâncias dos inimigos.
    -   **chao (TileMapLayer)**: TileMap do chão.
    -   **paredes (TileMapLayer)**: TileMap das paredes.
    -   **HUD (CanvasLayer)**: Camada para a interface do usuário.
        -   **Script**: Deve ter o script `HUD.gd` anexado.
        -   **HealthBar (ProgressBar)**: A barra de vida do jogador.
        -   **Label (Label)**: Rótulo para exibir o texto da vida.
    -   **GameOverScreen (ColorRect)**: A tela que aparece ao final do jogo.

### 1.2. Configuração no Inspetor

1.  **Selecione o nó `main`**:
    *   Arraste o nó `Player` para a variável `Player`.
    *   Arraste o nó `Node` (contêiner) para `Enemies Container`.
    *   Arraste o `TileMapLayer` `chao` para `Floor Tilemap`.
    *   Arraste o `TileMapLayer` `paredes` para `Walls Tilemap`.
    *   Arraste o `ColorRect` `GameOverScreen` para `Game Over Layer`.

2.  **Selecione o nó `Player`**:
    *   Arraste a `ProgressBar` de dentro do `HUD` para a variável `Health Bar` do jogador.

3.  **Selecione o nó `HUD`**:
    *   Arraste a `ProgressBar` para a variável `Health Bar` do HUD.
    *   Arraste o `Label` para a variável `Health Label` do HUD.

## 2. Configuração de Grupos e Sinais

### 2.1. Grupos
-   **Jogador**: Deve estar no grupo `"player"`.
-   **Inimigos**: Devem estar no grupo `"enemies"`.

### 2.2. Sinais (Conexões no Editor)
-   O sinal `health_updated(current, max)` do nó `Player` deve ser conectado à função `_on_player_health_updated(current, max)` no script do `HUD`.
-   O sinal `player_died` do nó `Player` deve ser conectado à função `_on_player_died()` no script do `dungeon_generator.gd`.

## 3. Funcionalidades do Jogo

-   **Combate**: Ataque os inimigos movendo-se para cima deles. Eles retaliarão em seus turnos.
-   **Morte do Inimigo**: Ao ter a vida zerada, o inimigo tocará uma animação de morte e será removido.
-   **Morte do Jogador**: Ao ter a vida zerada, a tela de "Game Over" aparecerá e o jogo será pausado.
-   **Passar o Turno**: Pressione a **Barra de Espaço** para pular seu turno.

## 4. Deploy Automático (GitHub Pages)

O deploy automático continua funcionando como antes. Cada `push` na branch `main` irá atualizar a versão online do jogo.
-   **URL do Jogo**: **https://zednaked.github.io/sirpeidalot/**
