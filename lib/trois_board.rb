require_relative './piece_stack'

class TroisBoard
  attr_reader :cols, :rows, :pieces

  def initialize(cols = 4, rows = 4)
    @cols = cols
    @rows = rows
    clear!
  end

  def setup
    6.times do
      randomly_add_pieces([random_piece])
    end
  end

  def randomly_add_pieces(piece_list)
    piece_list.each do |piece|
      pos = find_empty_spot
      self.add_piece(piece, pos)
    end
  end

  def clear!
    @pieces = Array.new(self.cols) do |col|
      Array.new(self.rows)
    end
  end

  def slide_up
    slide_board(0, -1)
  end

  def slide_down
    slide_board(0, 1)
  end

  def slide_left
    slide_board(-1, 0)
  end

  def slide_right
    slide_board(1, 0)
  end

  def slide_up!
    return unless self.can_move_up?

    replace_board!(slide_up_with_new_piece)
  end

  def slide_up_with_new_piece
    slide_up.tap do |new_board|
      columns = moved_columns(new_board)
      new_board.add_piece(random_piece, Pos.new(columns.sample, (self.rows - 1)))
    end
  end

  def slide_down!
    return unless self.can_move_down?

    replace_board!(slide_down_with_new_piece)
  end

  def slide_down_with_new_piece
    slide_down.tap do |new_board|
      columns = moved_columns(new_board)
      new_board.add_piece(random_piece, Pos.new(columns.sample, 0))
    end
  end

  def slide_left!
    return unless self.can_move_left?

    replace_board!(slide_left_with_new_piece)
  end

  def slide_left_with_new_piece
    slide_left.tap do |new_board|
      rows = moved_rows(new_board)
      new_board.add_piece(random_piece, Pos.new((self.cols - 1), rows.sample))
    end
  end

  def slide_right!
    return unless self.can_move_right?

    replace_board!(slide_right_with_new_piece)
  end

  def slide_right_with_new_piece
    slide_right.tap do |new_board|
      rows = moved_rows(new_board)
      new_board.add_piece(random_piece, Pos.new(0, rows.sample))
    end
  end

  def add_piece(piece, pos)
    return false unless position_in_bounds?(pos)

    if placed_piece = self.piece_at(pos)
      placed_piece.merge_with(piece)
    else
      @pieces[pos.x][pos.y] = piece
    end
  end

  def find_empty_spot
    pos = random_position

    while position_taken?(pos)
      pos = random_position
    end

    return pos
  end

  def random_position
    Pos.new(rand(self.rows), rand(self.cols))
  end

  def can_move_to?(piece, pos)
    position_in_bounds?(pos) && (!self.position_taken?(pos) || self.piece_at(pos).can_merge?(piece))
  end

  def position_taken?(pos)
    !self.piece_at(pos).nil?
  end

  def piece_at(pos)
    return unless position_in_bounds?(pos)
    @pieces[pos.x][pos.y]
  end

  def playing?
    !self.available_moves.empty?
  end

  def available_moves
    [
      (:left  if self.can_move_left?),
      (:right if self.can_move_right?),
      (:up    if self.can_move_up?),
      (:down  if self.can_move_down?)
    ].compact
  end

  def points
    points = 0
    self.pieces.each do |col|
      col.each do |piece|
        points += piece.points if piece
      end
    end

    return points
  end

  def can_move_left?
    moved_left = self.slide_left
    self.pieces != moved_left.pieces
  end

  def can_move_right?
    moved_right = self.slide_right
    self.pieces != moved_right.pieces
  end

  def can_move_up?
    moved_up = self.slide_up
    self.pieces != moved_up.pieces
  end

  def can_move_down?
    moved_down = self.slide_down
    self.pieces != moved_down.pieces
  end

  def get_column(col)
    pieces = []
    self.rows.times do |row|
      pieces << self.piece_at(Pos.new(col, row))
    end

    return pieces
  end

  def get_row(row)
    pieces = []
    self.cols.times do |col|
      pieces << self.piece_at(Pos.new(col, row))
    end

    return pieces
  end

  def max_piece_value
    self.pieces.flatten.compact.collect { |x| x.value }.max
  end

  def positions_of(value)
    positions = []
    self.cols.times do |col|
      self.rows.times do |row|
        positions << [col, row] if self.piece_at(Pos.new(col, row)) == value
      end
    end

    return positions
  end

  def size
    self.pieces.flatten.compact.size
  end

  def next_piece
    piece_stack.last
  end

  def moved_columns(new_board)
    columns = (0..(self.cols - 1)).reject do |col|
      original_column = self.get_column(col)
      new_column      = new_board.get_column(col)
      pieces_match?(original_column, new_column)
    end
  end

  def moved_rows(new_board)
    rows = (0..(self.rows - 1)).reject do |row|
      original_row = self.get_row(row)
      new_row      = new_board.get_row(row)
      pieces_match?(original_row, new_row)
    end
  end

  private

  # This method assumes the stack has already been shuffled, and therefore the next piece is random
  def random_piece
    piece_stack.pop
  end

  def piece_stack
    @piece_stack ||= PieceStack.new
    @piece_stack.refill!(self.max_piece_value) if @piece_stack.size <= 1
    @piece_stack
  end

  def slide_board(x_offset, y_offset)
    new_board = self.class.new(self.cols, self.rows)
    x_offsets = (0..3).to_a
    y_offsets = (0..3).to_a
    x_offsets.reverse! if x_offset > 0
    y_offsets.reverse! if y_offset > 0

    x_offsets.each do |x|
      y_offsets.each do |y|
        current_pos = Pos.new(x, y)
        if piece = self.piece_at(current_pos)
          new_piece = Piece.new(piece.value)
          new_pos = Pos.new(current_pos.x + x_offset, current_pos.y + y_offset)
          unless new_board.can_move_to?(new_piece, new_pos)
            new_pos = current_pos
          end
          new_board.add_piece(new_piece, new_pos)
        end
      end
    end

    new_board
  end

  def pieces_match?(row1, row2)
    row1.collect { |p| p ? p.value : nil } == row2.collect { |p| p ? p.value : nil }
  end

  def replace_board!(new_board)
    @pieces = new_board.pieces
  end

  def position_in_bounds?(pos)
    0 <= pos.x && pos.x < self.cols && 0 <= pos.y && pos.y < self.rows
  end
end

