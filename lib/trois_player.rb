require_relative './trois_board'
require_relative './trois_board_printer'

class TroisPlayer
  attr_reader :board, :moves_made

  def initialize(board, debug = false)
    @board = board
    @debug = debug
    @moves_made = 0
  end

  def debug?
    @debug
  end

  def play
    depth = [(self.board.size / 3).to_i, 3].max
    moves = calculate_moves(depth)
    @initial_depth = nil
    _, best_move = find_best_move(moves)

    if best_move
      make_move(best_move)
      self.play
    else
      print_output
    end
  end

  def calculate_moves(depth = 5)
    @initial_depth ||= depth
    return {} if depth == 0

    board.available_moves.inject({}) do |potential_moves, direction|
      potential_moves[direction] = {
        score: average_score(board, direction, depth == @initial_depth),
        moves: calculate_moves(depth - 1)
      }

      potential_moves
    end
  end

  def average_score(board, direction, first_move = false)
    next_pieces = (first_move ? [board.next_piece] : next_possible_pieces(board))
    scores = next_pieces.collect { |piece| self.send("scores_slide_#{direction}", board, piece) }.flatten
    return 0 if scores.empty?

    scores.inject(0) { |sum, score| sum + score }.to_f / scores.size
  end

  def scores_slide_up(board, piece)
    board.moved_columns(board.slide_up).collect do |column|
      new_board = board.slide_up
      new_board.add_piece(piece, Pos.new(column, 0))
      score_board(new_board)
    end
  end

  def scores_slide_down(board, piece)
    board.moved_columns(board.slide_down).collect do |column|
      new_board = board.slide_down
      new_board.add_piece(piece, Pos.new(column, (board.cols - 1)))
      score_board(new_board)
    end
  end

  def scores_slide_left(board, piece)
    board.moved_rows(board.slide_left).collect do |row|
      new_board = board.slide_left
      new_board.add_piece(piece, Pos.new((board.rows - 1), row))
      score_board(new_board)
    end
  end

  def scores_slide_right(board, piece)
    board.moved_rows(board.slide_right).collect do |row|
      new_board = board.slide_right
      new_board.add_piece(piece, Pos.new(0, row))
      score_board(new_board)
    end
  end

  def next_possible_pieces(board)
    # just assume an even chance of a 1, 2 or 3 coming up
    [Piece.new(1), Piece.new(2), Piece.new(3)]
  end

  def score_board(board)
    score = board.points * board.available_moves.size / 4
    score *= 1 + (0.1 * top_pieces_adjacent(board))
    score *= 1 + (0.1 * encourage_adjacent_matches(board, board.max_piece_value))
    score *= 1 + (0.2 * open_spots(board))

    return score
  end

  # discover the number of adjacent matches. joins should be
  # preferred as this encouraged by the higher points
  def encourage_adjacent_matches(board, max_piece, adjacent = 0)
    return adjacent if max_piece < 3

    if pieces_adjacent?(board, max_piece, max_piece)
      adjacent = encourage_adjacent_matches(board, max_piece / 2, adjacent + 1)
    end

    return adjacent
  end

  # this encourages "rivers" to form
  def top_pieces_adjacent(board, max_piece = nil, adjacent = 0)
    max_piece ||= board.max_piece_value
    next_piece = max_piece / 2
    if (pieces_adjacent?(board, max_piece, next_piece))
      adjacent = top_pieces_adjacent(board, next_piece, adjacent + 1)
    end

    return adjacent
  end

  def pieces_adjacent?(board, value1, value2)
    positions_of_value1 = board.positions_of(value1)
    offsets = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    offsets.any? { |col, row| board.piece_at(Pos.new(col, row)) == value2 }
  end

  def open_spots(board)
    return (board.rows * board.cols) - board.size
  end

  def find_best_move(moves)
    max_score = 0
    max_direction = nil
    return [0, nil] if moves.nil? || moves.empty?

    moves.each do |direction, attrs|
      debug_score(direction, attrs[:score]) if self.debug?
      if attrs[:score] > max_score
        max_score = attrs[:score]
        max_direction = direction
      elsif attrs[:score] == max_score && rand > 0.5
        max_score = attrs[:score]
        max_direction = direction
      end
      potential_score, _ = find_best_move(attrs[:moves])
      if potential_score > max_score
        max_score = potential_score
        max_direction = direction
      end
    end

    return [max_score, max_direction]
  end

  def make_move(direction)
    board.send("slide_#{direction}!")
    @moves_made += 1
    puts "\nMove #{@moves_made}:\n#{direction}#{print_board}\n" if self.debug?
  end

  def debug_score(direction, score)
    puts "Score for #{direction}: #{score}"
  end

  def print_output
    print_board
    print_score
    print_moves_made
  end

  def print_board
    puts TroisBoardPrinter.new(self.board).print_board
  end

  def print_score
    puts "Final score: #{self.board.points} pts"
  end

  def print_moves_made
    puts "Made #{self.moves_made} moves"
  end
end

