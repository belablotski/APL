
# APL Tool: check_winner
# Version: 0.1
# Description: Checks for a winner or a draw.

tool_definition:
  name: check_winner
  description: "Checks for a winner or a draw."

  inputs:
    - name: board
      required: true

  outputs:
    - name: winner
      description: "The winner (X, O, Draw, or None)."
    - name: game_over
      description: "True if the game is over."

  run:
    - name: "Agent checks for winner"
      tool: agent_native # This is a placeholder for the agent's reasoning
      prompt: "Given the board state, check for a winner or a draw."
      with_inputs:
        board: "{{board}}"
      register: check_result

    - name: "Set winner and game_over"
      tool: set_vars
      vars:
        winner: "{{check_result.winner}}"
        game_over: "{{check_result.game_over}}"
