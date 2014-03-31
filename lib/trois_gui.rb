# require "curses"
# include Curses
require 'io/console'
require_relative "./trois_board"
require_relative "./piece"

class TroisGui
  attr_reader :board

  def initialize
    # @win = Window.new
    @board = TroisBoard.new
    pieces = []
    6.times do
      pieces << Piece.new(rand(3).to_i + 1)
    end
    @board.randomly_add_pieces(pieces)
    self.run
  end

  def run
    running = true
    while running
      self.print_board
      case STDIN.getch
        when 'j'
          board.slide_down!
        when 'k'
          board.slide_up!
        when 'h'
          board.slide_left!
        when 'l'
          board.slide_right!
        when 'q'
          running = false
        end
    end
  end

  def print_board
    print_separator
    4.times do |row|
      4.times do |col|
        piece = board.piece_at(Pos.new(col, row))
        print "+"
        if piece
          print center_number(piece.value)
        else
          print " " * self.spot_width
        end
      end
      puts "+"
      print_separator
    end
  end

  def print_separator
    puts "+====+====+====+====+"
  end

  def center_number(num)
    pad_left = (self.spot_width - num.to_s.length) / 2
    pad_right = self.spot_width - num.to_s.length - pad_left

    " " * pad_left + num.to_s + " " * pad_right
  end

  def spot_width
    4
  end

  def get_char
    STDIN.getc.chr
  end
end

