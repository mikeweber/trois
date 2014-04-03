$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/trois_board'
require 'lib/trois_player'

board = TroisBoard.new
board.setup
player = TroisPlayer.new(board, true)
player.play

