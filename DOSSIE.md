# Dossiê Técnico: Sistema de Turnos

Este documento detalha a arquitetura e o fluxo de dados do sistema de combate por turnos implementado no projeto.

## 1. Visão Geral da Arquitetura

O sistema é centralizado em um nó "gerenciador" e se comunica com as entidades (jogador, inimigos) através de sinais e chamadas de método. A lógica é desacoplada: o gerenciador não precisa saber *o que* um inimigo faz, apenas *quando* ele deve agir e *quando* ele terminou.

### Componentes Principais:

1.  **`dungeon_generator.gd` (O Gerenciador de Turnos)**
    *   **Responsabilidade**: Orquestrar o fluxo do jogo, determinar de quem é o turno, e fornecer serviços (como pathfinding A*) para outras entidades.
    *   **Nó**: Anexado ao nó `main` da cena.

2.  **`player.gd` (O Jogador)**
    *   **Responsabilidade**: Capturar a entrada do usuário e traduzi-la em ações de jogo (mover, atacar, passar o turno). Só pode agir quando o Gerenciador permite.
    *   **Nó**: A cena `Jogador.tscn`.

3.  **`esqueleto.gd` (O Inimigo)**
    *   **Responsabilidade**: Implementar a lógica de IA para decidir o que fazer em seu turno (atacar ou mover-se em direção ao jogador).
    *   **Nó**: A cena `esqueleto.tscn`.

## 2. Fluxo de um Turno Completo

O ciclo de jogo opera da seguinte forma:

1.  **Início do Jogo**:
    *   `dungeon_generator.gd` entra no estado `PLAYER_TURN`.
    *   Ele chama `player.set_can_act(true)` para habilitar a entrada do jogador.

2.  **Ação do Jogador**:
    *   O jogador pressiona uma tecla de movimento ou a barra de espaço.
    *   `player.gd` executa a ação (calcula o movimento, ataca ou simplesmente passa o turno).
    *   Ao final da ação, o `player.gd` emite o sinal `action_taken`.

3.  **Início do Turno dos Inimigos**:
    *   `dungeon_generator.gd` recebe o sinal `action_taken`.
    *   Ele verifica se ainda existem inimigos. Se não, entra no modo `FREE_ROAM` e o ciclo de turnos termina.
    *   Se há inimigos, ele chama `player.set_can_act(false)` para desabilitar a entrada do jogador.
    *   O estado muda para `ENEMY_TURN`.
    *   O gerenciador chama a função `_process_enemy_turns()`.

4.  **Ações dos Inimigos**:
    *   `_process_enemy_turns()` itera sobre cada inimigo no `enemies_container`.
    *   Para cada inimigo, ele chama o método `take_turn()`.
    *   O gerenciador então usa `await enemy.action_taken` para pausar a execução e esperar que o inimigo atual termine sua ação.
    *   Dentro de `take_turn()`, o `esqueleto.gd` decide se ataca (se o jogador estiver adjacente) ou se move.
    *   Para se mover, ele solicita um caminho ao `dungeon_generator.calculate_path()`.
    *   Após a animação de ataque ou movimento ser concluída, o `esqueleto.gd` emite o sinal `action_taken`.

5.  **Fim do Turno dos Inimigos**:
    *   O `await` no gerenciador é satisfeito, e o loop continua para o próximo inimigo.
    *   Quando todos os inimigos agiram, a função `_process_enemy_turns()` chama `_end_enemy_turn_sequence()`.
    *   O estado volta para `PLAYER_TURN`.
    *   O gerenciador chama `player.set_can_act(true)`.
    *   O ciclo recomeça no passo 2.

## 3. Sinais e Métodos Chave

### `dungeon_generator.gd`
*   **Sinais Emitidos**: `player_turn_started`, `enemy_turn_started`.
*   **Sinais Escutados**: `action_taken` (do jogador e dos inimigos).
*   **Métodos Principais**:
    *   `_on_player_action_taken()`: Ponto de entrada para o turno dos inimigos.
    *   `_process_enemy_turns()`: Orquestra as ações dos inimigos sequencialmente.
    *   `calculate_path()`: Fornece o serviço de pathfinding A*.

### `player.gd`
*   **Sinais Emitidos**: `action_taken`.
*   **Métodos Principais**:
    *   `_unhandled_input()`: Captura as intenções do jogador.
    *   `set_can_act(bool)`: Habilita ou desabilita a capacidade do jogador de agir.

### `esqueleto.gd`
*   **Sinais Emitidos**: `action_taken`.
*   **Métodos Principais**:
    *   `take_turn()`: Ponto de entrada para a lógica de IA do inimigo.
    *   `set_turn_manager()`: Usado para injeção de dependência, permitindo que o esqueleto acesse o gerenciador.

## 4. Controle de Versão e Deploy (CI/CD)

O projeto utiliza **Git** para controle de versão e **GitHub Actions** para automação do processo de build e deploy para o **GitHub Pages**.

### 4.1. Estrutura do Workflow

O pipeline de CI/CD está definido em `.github/workflows/deploy.yml`. Ele é acionado a cada `push` na branch `main`.

O workflow consiste em dois trabalhos (`jobs`) que rodam em sequência:

1.  **`build` (Construção)**:
    *   **`actions/checkout@v4`**: Baixa o código-fonte do repositório para o ambiente da action.
    *   **`abarichello/godot-ci@4.2.2-stable`**: Ação principal. Ela utiliza uma imagem Docker com o Godot para exportar o projeto.
        *   **`preset: "Web-Pages"`**: Instrui o Godot a usar o preset de exportação específico para a web que foi configurado no arquivo `export_presets.cfg`.
        *   **`path: "build/"`**: Define o diretório de saída para os arquivos do jogo construído.
    *   **`actions/upload-pages-artifact@v3`**: Pega o conteúdo da pasta `build/` e o empacota como um "artefato", preparando-o para o próximo trabalho.

2.  **`deploy` (Publicação)**:
    *   **`needs: build`**: Este trabalho só começa se o trabalho `build` for concluído com sucesso.
    *   **`actions/deploy-pages@v4`**: Uma ação oficial do GitHub que pega o artefato criado no passo anterior e o publica no ambiente do GitHub Pages, tornando o jogo acessível online.

### 4.2. Arquivos de Configuração

*   **`.gitignore`**: Contém uma entrada para `build/` para garantir que a pasta de build local nunca seja enviada para o repositório, pois ela é gerada automaticamente pela action.
*   **`export_presets.cfg`**: Arquivo gerado pelo Godot que contém todas as configurações do preset de exportação "Web-Pages", incluindo o caminho de saída e outras opções de build. É essencial que este arquivo esteja no repositório.