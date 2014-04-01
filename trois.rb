$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/trois_board'
require 'lib/trois_gui'

gui = TroisGui.new
gui.run
gui.window << "\nPress any key to quit"
gui.window.getch

