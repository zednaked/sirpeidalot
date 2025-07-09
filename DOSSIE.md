# Dossiê Técnico: Sistema de Jogo

Este documento detalha a arquitetura e os fluxos de dados do projeto, incluindo o sistema de turnos, a interface do usuário (HUD) e o ciclo de fim de jogo.

## 1. Visão Geral da Arquitetura

O sistema é centralizado em um nó "gerenciador" (`dungeon_generator.gd`) que orquestra o fluxo de jogo. As entidades (jogador, inimigos) são semi-independentes e comunicam seu estado através de sinais. Uma camada de UI (`HUD`) escuta esses sinais para exibir informações relevantes.

### Componentes Principais:

1.  **`dungeon_generator.gd` (O Gerenciador de Jogo)**
    *   **Responsabilidade**: Orquestrar o fluxo de turnos, fornecer pathfinding A*, e gerenciar o estado global do jogo (como "Game Over").
    *   **Nó**: Anexado ao nó `main` da cena.

2.  **`player.gd` (O Jogador)**
    *   **Responsabilidade**: Gerenciar os atributos do jogador (vida, dano), capturar input, executar ações e emitir sinais sobre seu estado (`health_updated`, `player_died`, `action_taken`).
    *   **Nó**: A cena `Jogador.tscn`.

3.  **`esqueleto.gd` (O Inimigo)**
    *   **Responsabilidade**: Implementar a IA de combate, gerenciar seus próprios atributos e emitir um sinal (`action_taken`) ao final de seu turno.
    *   **Nó**: A cena `esqueleto.tscn`.

4.  **`HUD.gd` (Interface do Usuário)**
    *   **Responsabilidade**: Escutar os sinais do jogador (`health_updated`) e atualizar os elementos visuais da interface, como a barra de vida.
    *   **Nó**: Anexado ao `CanvasLayer` chamado `HUD`.

## 2. Fluxos de Jogo

### 2.1. Fluxo de Combate por Turnos

O fluxo de turnos permanece o mesmo:
`Jogador age` -> `emite action_taken` -> `Gerenciador recebe` -> `Inimigos agem em sequência` -> `emitem action_taken` -> `Gerenciador devolve o turno ao jogador`.

### 2.2. Fluxo de Atualização da UI (Vida)

1.  O jogador ou um inimigo executa uma ação de ataque.
2.  O alvo do ataque chama sua função `take_damage(amount)`.
3.  No `player.gd`, a função `take_damage` emite o sinal `health_updated` com a vida atual e a vida máxima.
4.  O script `HUD.gd` recebe este sinal e atualiza o valor da `ProgressBar` (barra de vida).

### 2.3. Fluxo de Fim de Jogo (Game Over)

1.  O jogador recebe dano e sua vida chega a 0 ou menos.
2.  A função `take_damage` do jogador emite o sinal `player_died`.
3.  O `dungeon_generator.gd` recebe o sinal `player_died`.
4.  O gerenciador executa a lógica de fim de jogo:
    *   Mostra a tela de "Game Over" (`GameOverScreen`).
    *   Pausa a árvore de cena com `get_tree().paused = true`, congelando o jogo.

## 3. Sinais e Métodos Chave

### `dungeon_generator.gd`
*   **Sinais Escutados**: `action_taken` (de todos), `player_died` (do jogador).
*   **Responsabilidades Adicionais**: Gerenciar a visibilidade da tela de "Game Over" e pausar o jogo.

### `player.gd`
*   **Sinais Emitidos**: `action_taken`, `health_updated(current_health, max_health)`, `player_died`.
*   **Atributos Chave**: `@export var health_bar: ProgressBar` para a referência da UI.
*   **Métodos Adicionais**: `take_damage()` agora contém a lógica de morte.

### `esqueleto.gd`
*   **Métodos Adicionais**: `_die()` agora toca a animação de morte antes de remover o nó.

### `HUD.gd`
*   **Sinais Escutados**: `health_updated`.
*   **Responsabilidade**: Conectar a lógica do jogo com os elementos da interface.

## 4. Controle de Versão e Deploy (CI/CD)

O projeto utiliza **Git** e **GitHub Actions** para automação do build e deploy para o **GitHub Pages**, conforme detalhado na versão anterior deste documento.
