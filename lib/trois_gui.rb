require "curses"
require 'io/console'
require_relative "./trois_board"
require_relative "./piece"

class TroisGui
  attr_reader :board, :window

  def initialize
    Curses.noecho
    Curses.init_screen
    @window = Curses::Window.new(12, 21, 0, 0)
    @board = TroisBoard.new
    pieces = []
    6.times do
      pieces << Piece.new(rand(3).to_i + 1)
    end
    self.board.randomly_add_pieces(pieces)
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
    print_next_piece
    print_separator
    4.times do |row|
      4.times do |col|
        piece = board.piece_at(Pos.new(col, row))
        window << "+"
        if piece
          window << center_number(piece.value)
        else
          window << " " * self.spot_width
        end
      end
      window << "+"
      print_separator
    end
    window.refresh
  end

  def print_next_piece
    window << "         +=+\n"
    window << "         |#{next_piece_value}|\n"
  end

  def next_piece_value
    next_piece = board.next_piece
    next_piece.value > 3 ? "+" : next_piece.value
  end

  def print_separator
    window << "+====+====+====+====+"
  end

  def center_number(num)
    pad_left = (self.spot_width - num.to_s.length) / 2
    pad_right = self.spot_width - num.to_s.length - pad_left

    " " * pad_left + num.to_s + " " * pad_right
  end

  def spot_width
    4
  end
end

