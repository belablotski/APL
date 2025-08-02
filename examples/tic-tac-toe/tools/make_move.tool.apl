
# APL Tool: make_move
# Version: 0.1
# Description: Makes a move for the current player.

tool_definition:
  name: make_move
  description: "Makes a move for the current player."

  inputs:
    - name: board
      required: true
    - name: player
      required: true

  outputs:
    - name: new_board
      description: "The board after the move."

  run:
    - name: "Agent makes a move"
      tool: agent_native # This is a placeholder for the agent's reasoning
      prompt: "Given the board state, make a valid move for the current player."
      with_inputs:
        board: "{{board}}"
        player: "{{player}}"
      register: agent_move

    - name: "Update board with agent's move"
      tool: set_vars
      vars:
        new_board: "{{agent_move.new_board}}" # The agent is expected to return the new board state
