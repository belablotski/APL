# APL Program: Tic-Tac-Toe
# Version: 0.2
# Description: A simple Tic-Tac-Toe game where the agent plays against itself.

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

main:
  foreach:
    in: [1, 2, 3, 4, 5, 6, 7, 8, 9] # Max 9 turns
    loop_var: turn
    directives:
      - FORCE_FULL_LOOP_EXECUTION
  run:
    - name: "Display Board"
      tool: log
      if: "game_over == false"
      message: |
        Turn {{turn}}: Player {{current_player}}'s move
        {{board.0.0}}|{{board.0.1}}|{{board.0.2}}
        -+-+-
        {{board.1.0}}|{{board.1.1}}|{{board.1.2}}
        -+-+-
        {{board.2.0}}|{{board.2.1}}|{{board.2.2}}

    - name: "Player Move"
      tool: make_move
      if: "game_over == false"
      with_inputs:
        board: "{{board}}"
        player: "{{current_player}}"
      register: move_result

    - name: "Update Board"
      tool: set_vars
      if: "game_over == false"
      vars:
        board: "{{move_result.new_board}}"

    - name: "Check for Winner"
      tool: check_winner
      if: "game_over == false"
      with_inputs:
        board: "{{board}}"
      register: winner_check

    - name: "Update Game State"
      tool: set_vars
      if: "game_over == false"
      vars:
        winner: "{{winner_check.winner}}"
        game_over: "{{winner_check.game_over}}"

    - name: "Switch Player"
      tool: set_vars
      if: "game_over == false"
      vars:
        current_player: "{{'O' if current_player == 'X' else 'X'}}"

    - name: "End Game if Over"
      tool: log
      if: "game_over == true"
      message: "Game Over! Winner is {{winner}}"

finalize:
  - name: "Final Game Status"
    tool: log
    message: |
      Final Board:
      {{board.0.0}}|{{board.0.1}}|{{board.0.2}}
      -+-+-
      {{board.1.0}}|{{board.1.1}}|{{board.1.2}}
      -+-+-
      {{board.2.0}}|{{board.2.1}}|{{board.2.2}}
      Winner: {{winner}}