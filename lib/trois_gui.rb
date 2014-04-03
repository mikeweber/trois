require "curses"
require 'io/console'
require_relative "./trois_board"
require_relative "./piece"

class TroisGui
  attr_reader :board, :window

  def initialize
    Curses.noecho
    Curses.init_screen
    @window = Curses::Window.new(12, 22, 0, 0)
    @board = TroisBoard.new
    @board.setup
  end

  def run
    running = true
    self.print_board(self.board)
    while running
      char = window.getch
      case char
        when ' '
          @temp_move = nil
          self.print_board(self.board)
        when ?j, ?s
          self.make_move(:down)
        when ?w, ?k
          self.make_move(:up)
        when ?a, ?h
          self.make_move(:left)
        when ?d, ?l
          self.make_move(:right)
        when ?J, ?S
          make_temp_move(:down)
        when ?W, ?K
          make_temp_move(:up)
        when ?A, ?H
          make_temp_move(:left)
        when ?D, ?L
          make_temp_move(:right)
        when ?Q, ?q
          running = false
        end
      running = self.board.playing? if running
    end
    window << "Game over: #{board.points} pts"
    window.refresh
  end

  def make_move(direction)
    @temp_move = nil
    self.board.send("slide_#{direction}!")
    self.print_board(self.board)
  end

  def make_temp_move(direction)
    unless @temp_move == direction
      @temp_move = direction
      self.print_board(self.board.send("slide_#{direction}"), true)
    end
  end

  def print_board(board, temp = false)
    window.clear
    window << TroisBoardPrinter.new(board).print_board
    window.refresh
  end
end

