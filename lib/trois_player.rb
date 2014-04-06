require 'curses'
require 'logger'
require 'pp'
require_relative './trois_board'
require_relative './trois_board_printer'

class TroisPlayer
  attr_reader :board, :moves_made, :window, :logger

  def initialize(board, debug = false)
    logfile = File.open("debug.log", File::WRONLY | File::APPEND | File::CREAT)
    @logger = Logger.new(logfile)
    @board = board
    unless @debug = debug
      Curses.noecho
      Curses.init_screen
      @window = Curses::Window.new(20, 22, 0, 0)
    end
    @moves_made = 0
  end

  def play
    depth = 3
    best_move = self.best_move(depth)

    if best_move
      make_move(best_move)
      self.play
    else
      print_output
      window.getch if window
    end
  end

  def best_move(depth)
    @initial_depth = nil
    moves = calculate_moves(self.board, depth)
    if debug?
      # print_tree(moves)
      print_out max_scores_per_direction(moves).inspect
      # print_out "press enter to continue"
      # gets
    end
    _, best_move = find_best_move(moves)

    return best_move
  end

  def calculate_moves(board, depth = 5)
    @initial_depth ||= depth
    return if depth == 0

    moves = board.available_moves.inject({}) do |potential_moves, direction|
      potential_moves[direction] = { scores: [], moves: [] }
      next_possible_pieces(board, depth == @initial_depth).each do |piece|
        scores = self.send("scores_slide_#{direction}", board, piece)
        scores.each do |next_board, score|
          potential_moves[direction][:scores] << score
          potential_moves[direction][:moves] << calculate_moves(next_board, depth - 1)
          potential_moves[direction][:moves].compact!
        end
      end

      potential_moves
    end


    return moves
  end

  def scores_slide_up(board, piece)
    board.moved_columns(board.slide_up).collect do |column|
      new_board = board.slide_up
      new_board.add_piece(piece, Pos.new(column, 0))
      [new_board, score_board(board, new_board)]
    end
  end

  def scores_slide_down(board, piece)
    board.moved_columns(board.slide_down).collect do |column|
      new_board = board.slide_down
      new_board.add_piece(piece, Pos.new(column, (board.cols - 1)))
      [new_board, score_board(board, new_board)]
    end
  end

  def scores_slide_left(board, piece)
    board.moved_rows(board.slide_left).collect do |row|
      new_board = board.slide_left
      new_board.add_piece(piece, Pos.new((board.rows - 1), row))
      [new_board, score_board(board, new_board)]
    end
  end

  def scores_slide_right(board, piece)
    board.moved_rows(board.slide_right).collect do |row|
      new_board = board.slide_right
      new_board.add_piece(piece, Pos.new(0, row))
      [new_board, score_board(board, new_board)]
    end
  end

  def next_possible_pieces(board, first_move = false)
    if first_move
      [board.next_piece]
    else
      # just assume an even chance of a 1, 2 or 3 coming up
      [Piece.new(1), Piece.new(2), Piece.new(3)]
    end
  end

  def score_board(previous_board, board)
    adjacent_score = 1
    max_value = board.max_piece_value
    while max_value >= 3
      adjacent_score *= (1 + (0.2 * encourage_adjacent_matches(board, max_value) * Piece.rank_of(max_value)))
      max_value /= 2
    end
    adjacent_score *= (1 + (encourage_adjacent_matches(board, 2, 1)))
    adjacent_score *= (1 + (encourage_adjacent_matches(board, 1, 2)))

    scores = {
      base:       board.points,
      moves:      (board.available_moves.size / 4),
      river:      (1 + (0.1 * encourage_river(board))),
      adjacency:  adjacent_score,
      openness:   [(open_spots(board) - open_spots(previous_board) + 1), 0].max
    }
    logger.info(scores)

    return scores.values.inject(1) { |score, value| score * value }
  end

  # discover the number of adjacent matches. joins should be
  # preferred as they are encouraged by the higher points
  def encourage_adjacent_matches(board, max_piece, other_piece = nil)
    other_piece ||= max_piece

    pieces_adjacent?(board, max_piece, other_piece) ? 1 : 0
  end

  # this encourages "rivers" to form
  def encourage_river(board, max_piece = nil, positions = [], adjacent = 0)
    max_piece ||= board.max_piece_value
    next_piece = max_piece / 2
    next_positions = []

    next_positions = if positions.empty?
      board.positions_of(max_piece)
    else
      positions.collect { |pos| positions_of_adjacent_pieces(board, max_piece, pos) }.flatten
    end

    return adjacent if next_positions.empty?

    new_adjacent = encourage_river(board, next_piece, next_positions, adjacent + 1)
    adjacent = new_adjacent if new_adjacent > adjacent

    return adjacent
  end

  def pieces_adjacent?(board, value1, value2)
    positions_of_value1 = board.positions_of(value1)
    offsets = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    offsets.any? do |col, row|
      positions_of_value1.any? do |v1_col, v1_row|
        board.piece_at(Pos.new(col + v1_col, row + v1_row)) == value2
      end
    end
  end

  def positions_of_adjacent_pieces(board, value, pos)
    offsets = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    positions = offsets.collect do |col, row|
      new_pos = Pos.new(pos[0] + col, pos[1] + row)
      new_pos if board.piece_at(new_pos) == value
    end

    return positions.compact
  end

  def open_spots(board)
    return (board.rows * board.cols) - board.size
  end

  def find_best_move(moves)
    max_score = 0
    max_direction = nil
    return [0, nil] if moves.nil? || moves.empty?

    scores = max_scores_per_direction(moves)
    logger.info(scores)
    scores.each do |score, direction|
      if score > max_score
        max_score = score 
        max_direction = direction
      end
    end
    directions = scores.select { |score, direction| score == max_score }

    return directions.sample
  end

  def max_scores_per_direction(moves)
    moves.collect do |direction, attrs|
      max_score = 0
      max_direction = nil

      debug_score(direction, attrs[:scores]) if self.debug? && attrs
      unless attrs.nil? || attrs[:scores].nil? || attrs[:scores].empty?
        if attrs[:scores].max > max_score
          max_score = attrs[:scores].max
          max_direction = direction
        elsif attrs[:scores].max == max_score && rand > 0.5
          max_score = attrs[:scores].max
          max_direction = direction
        end

        potential_score, _ = find_best_move(attrs[:moves])
        if potential_score > max_score
          max_score = potential_score
          max_direction = direction
        end
      end

      [max_score, max_direction]
    end
  end

  def make_move(direction)
    board.send("slide_#{direction}!")
    @moves_made += 1
    window.clear if window
    print_out "\nMove #{moves_made}:\n#{direction}\n#{print_board}\n"
    window.refresh if window
  end

  def debug_score(direction, score)
    print_out "Score for #{direction}: #{score}"
  end

  def print_output
    window.clear if window
    print_board
    print_score
    print_moves_made
    window.refresh if window
  end

  def print_tree(tree)
    pp tree
  end

  def print_board
    print_out TroisBoardPrinter.new(self.board).print_board
  end

  def print_score
    print_out "Final score: #{self.board.points} pts"
  end

  def print_moves_made
    print_out "\nMade #{self.moves_made} moves"
  end

  def print_out(msg)
    if window
      window << msg
    else
      puts msg
    end
  end

  def debug?
    @debug
  end

  def tree_node_size(tree)
    if tree.nil? || tree.size == 0
      return 0
    end
    tree.inject(0) do |size, key_attrs|
      direction, attrs = key_attrs
      if attrs
        size + attrs[:scores].size + tree_node_size(attrs[:moves])
      else
        size
      end
    end
  end
end

