# APL Program: Tic-Tac-Toe
# Version: 0.4
# Description: A simple Tic-Tac-Toe game where the agent plays against itself, using a while loop.

local_tool_paths:
  - ./tools/

setup:
  - name: "Initialize Game"
    tool: set_vars
    vars:
      board:
        - [" ", " ", " "]
        - [" ", " ", " "]
        - [" ", " ", " "]
      current_player: "X"
      winner: "None"
      game_over: false
      turn: 1

main:
  while: "game_over == false and turn <= 9"
  run:
    - name: "Display Board"
      tool: log
      message: |
        Turn {{turn}}: Player {{current_player}}'s move
        {{board.0.0}}|{{board.0.1}}|{{board.0.2}}
        -+-+-
        {{board.1.0}}|{{board.1.1}}|{{board.1.2}}
        -+-+-
        {{board.2.0}}|{{board.2.1}}|{{board.2.2}}

    - name: "Player Move"
      tool: make_move
      with_inputs:
        board: "{{board}}"
        player: "{{current_player}}"
      register: move_result

    - name: "Update Board"
      tool: set_vars
      vars:
        board: "{{move_result.new_board}}"

    - name: "Check for Winner"
      tool: check_winner
      with_inputs:
        board: "{{board}}"
      register: winner_check

    - name: "Update Game State"
      tool: set_vars
      vars:
        winner: "{{winner_check.winner}}"
        game_over: "{{winner_check.game_over}}"

    - name: "Switch Player and Increment Turn"
      tool: set_vars
      # Only switch player if the game isn't over, to keep the winner as the last player
      if: "game_over == false"
      vars:
        current_player: "{{'O' if current_player == 'X' else 'X'}}"
        turn: "{{ turn + 1 }}"

finalize:
  - name: "Announce Winner"
    tool: log
    if: "winner != 'None'"
    message: "Game Over! Winner is {{winner}}"
  - name: "Announce Draw"
    tool: log
    if: "winner == 'None'"
    message: "Game Over! It's a draw."
  - name: "Final Game Status"
    tool: log
    message: |
      Final Board:
      {{board.0.0}}|{{board.0.1}}|{{board.0.2}}
      -+-+-
      {{board.1.0}}|{{board.1.1}}|{{board.1.2}}
      -+-+-
      {{board.2.0}}|{{board.2.1}}|{{board.2.2}}
