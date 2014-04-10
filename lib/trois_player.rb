require 'curses'
require 'logger'
require 'pp'
require_relative './trois_board'
require_relative './trois_board_printer'

class TroisPlayer
  attr_reader :board, :moves_made, :window, :logger

  def self.cache_board_score(board, score)
    @@board_cache ||= {}
    @@board_cache[board] = score
  end

  def self.board_cache(board)
    @@board_cache ||= {}
    @@board_cache[board]
  end

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
    time = Time.now
    moves = calculate_moves(self.board, depth)
    logger.info("Move calculation of #{tree_node_size(moves)} nodes took #{Time.now - time}s")
    best_move, _ = find_best_move(moves)

    return best_move
  end

  def calculate_moves(board, depth = 5)
    @initial_depth ||= depth
    return if depth == 0

    # to speed up the game, repeat up and left moves until a 48 pt piece exists
    if board.max_piece_value <= 48
      preferred_moves = [:up, :left, :right, :down]
      preferred_moves.each do |direction|
        if board.available_moves.include?(direction)
          return { direction => { scores: [1], moves: [] }}
        end
      end
    end
    moves = board.available_moves.inject({}) do |potential_moves, direction|
      potential_moves[direction] = { scores: [], moves: [] }
      next_possible_pieces(board, depth == @initial_depth).each do |piece|
        scores = self.send("scores_slide_#{direction}", board, piece)
        scores.each do |next_board, score_and_explanation|
          potential_moves[direction][:scores] << score_and_explanation
          if calculated_moves = calculate_moves(next_board, depth - 1)
            potential_moves[direction][:moves] << calculated_moves
          end
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
    if previous_score = self.class.board_cache(board)
      logger.info("Cache hit: #{previous_score}\n#{printed_board(board)}")
      return previous_score
    end

    adjacent_score = 1
    max_value = board.max_piece_value
    while max_value >= 3
      adjacent_score *= (1 + (0.5 * encourage_adjacent_matches(board, max_value) * Piece.rank_of(max_value)))
      max_value /= 2
    end
    adjacent_score *= (1 + (encourage_adjacent_matches(board, 2, 1)))
    adjacent_score *= (1 + (encourage_adjacent_matches(board, 1, 2)))

    explanations = {
      base:       board.points,
      moves:      (board.available_moves.size.to_f / 4),
      river:      (1 + (0.1 * encourage_river(board))),
      adjacency:  adjacent_score,
      openness:   (0.5 * [(open_spots(board) - open_spots(previous_board) + 1), 0.5].max)
    }

    calculated_score = explanations.values.inject(1) { |score, value| score * value }

    self.class.cache_board_score(board, calculated_score)
    return [calculated_score, explanations]
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
    potential_best_moves = []
    return [nil, 0] if moves.nil? || moves.empty?

    flattened_tree = self.flatten_tree(moves)
    flattened_tree.each do |direction, score|
      if score > max_score
        max_score = score
        potential_best_moves << [direction, score]
      end
    end
    logger.debug("Max scores: #{flattened_tree.inspect}")

    best_moves = potential_best_moves.select { |_, score| score == max_score }
    return best_moves.sample || []
  end

  def flatten_tree(moves)
    move_attrs = {}

    moves.each do |direction, attrs|
      next if attrs.nil?
      avg = avg(attrs[:scores].collect { |score, _| score })
      move_attrs[direction] = avg
      attrs[:moves].each do |other_moves|
        child_tree = self.flatten_tree(other_moves)
        child_tree.each do |_, child_avg|
          if child_avg > move_attrs[direction]
            move_attrs[direction] = child_avg
          end
        end
      end
    end

    return move_attrs
  end

  def make_move(direction)
    board.send("slide_#{direction}!")
    @moves_made += 1
    window.clear if window
    print_out "\nMove #{moves_made}:\n#{direction}\n#{print_board}\n"
    window.refresh if window
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

  def print_board(board = self.board)
    print_out printed_board(board)
  end

  def printed_board(board)
    TroisBoardPrinter.new(board).print_board
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

  def avg(array)
    return 0 if array.nil?
    array.inject(0) { |sum, el| sum + el }.to_f / array.size
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

