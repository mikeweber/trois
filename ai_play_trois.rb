require_relative './trois'
require 'lib/trois_player'

board = TroisBoard.new
board.setup
player = TroisPlayer.new(board, true)
player.play

