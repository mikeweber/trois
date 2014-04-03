class TroisBoardPrinter
  attr_accessor :window, :board

  def initialize(board)
    @board = board
    self.window = ""
  end

  def print_board
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
      window << "+\n"
      print_separator
    end

    window
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
    window << "+====+====+====+====+\n"
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

