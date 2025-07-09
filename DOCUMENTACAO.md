# Documentação do Projeto: Sistema de Turnos

Este documento fornece as instruções para configurar e usar o sistema de combate por turnos no editor Godot.

## 1. Configuração da Cena Principal (`main.tscn`)

Para que o sistema funcione, a cena principal precisa ter uma estrutura específica e as referências de nós devem ser configuradas corretamente.

### 1.1. Estrutura de Nós

Sua cena principal deve conter os seguintes nós:

-   **main (Node2D)**: O nó raiz da cena.
    -   **Script**: Deve ter o script `scripts/dungeon_generator.gd` anexado.
    -   **Player (Jogador.tscn)**: A instância da cena do jogador.
    -   **Node (Node)**: Um nó genérico que servirá como contêiner para todos os inimigos.
        -   **esqueleto (esqueleto.tscn)**: Instâncias da cena do inimigo devem ser filhas deste nó.
    -   **chao (TileMapLayer)**: A camada de TileMap para o chão.
    -   **paredes (TileMapLayer)**: A camada de TileMap para as paredes e obstáculos.
    -   **portas (TileMapLayer)**: A camada de TileMap para as portas.

### 1.2. Configuração no Inspetor

1.  Selecione o nó `main`.
2.  No painel "Inspetor", localize a seção "Script Variables".
3.  **Player**: Arraste o nó `Player` da árvore da cena para esta variável.
4.  **Enemies Container**: Arraste o nó `Node` (o contêiner de inimigos) para esta variável.
5.  **Floor Tilemap**: Arraste o `TileMapLayer` chamado `chao` para esta variável.
6.  **Walls Tilemap**: Arraste o `TileMapLayer` chamado `paredes` para esta variável.

## 2. Configuração de Grupos e Camadas

A comunicação entre os nós e a detecção de colisões dependem de grupos e camadas de física.

### 2.1. Grupos

-   **Jogador**:
    1.  Selecione o nó raiz da cena `Jogador.tscn` (ou o nó `Player` na cena principal).
    2.  Vá para a aba "Nó" (ao lado do "Inspetor") e selecione "Grupos".
    3.  Digite `player` e clique em "Adicionar".

-   **Inimigos**:
    1.  Selecione o nó raiz da cena `esqueleto.tscn`.
    2.  Vá para a aba "Nó" -> "Grupos".
    3.  Digite `enemies` e clique em "Adicionar".

### 2.2. Camadas de Física (Physics Layers)

Para que os ataques e interações funcionem corretamente, os corpos físicos precisam estar em camadas distintas.

1.  **Jogador**:
    -   Selecione o nó `Player`.
    -   No Inspetor, vá para `Collision` -> `Layer`.
    -   Marque a **Camada 1**. Desmarque as outras.

2.  **Inimigos (Esqueleto)**:
    -   Selecione o nó `esqueleto`.
    -   No Inspetor, vá para `Collision` -> `Layer`.
    -   Marque a **Camada 2**. Desmarque as outras.

3.  **RayCasts**:
    -   **Jogador**: Selecione o nó `InteractionRayCast` dentro do `Player`.
        -   No Inspetor, em `Collision Mask`, marque as camadas com as quais ele deve interagir (por exemplo, Camada 2 para inimigos, e a camada onde estiverem as portas).
    -   **Inimigo**: Se o inimigo usar um RayCast para visão, configure sua `Collision Mask` para detectar a Camada 1 (o jogador).

## 3. Funcionalidades do Jogador

-   **Movimento**: Use as setas direcionais para se mover um tile por vez.
-   **Ataque**: Mova-se em direção a um inimigo adjacente para atacá-lo.
-   **Passar o Turno**: Pressione a **Barra de Espaço** para pular seu turno sem realizar uma ação. Isso é útil para esperar que os inimigos se aproximem.
-   **Modo Livre**: Após todos os inimigos serem derrotados, o sistema de turnos é desativado e você pode se mover livremente pelo mapa.
