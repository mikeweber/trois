require_relative './trois_board'
require_relative './trois_board_printer'

class TroisPlayer
  attr_reader :board, :moves_made

  def initialize(board)
    @board = board
    @moves_made = 0
  end

  def play
    moves = calculate_moves
    _, best_move = find_best_move(moves)

    if best_move
      make_move(best_move)
      self.play
    else
      print_output
    end
  end

  def calculate_moves(depth = 3)
    return {} if depth == 0

    board.available_moves.inject({}) do |potential_moves, direction|
      potential_moves[direction] = {
        score: score_board(self.board.send("slide_#{direction}")),
        moves: calculate_moves(depth - 1)
      }

      potential_moves
    end
  end

  def score_board(board)
    board.points * board.available_moves.size / 4
  end

  def find_best_move(moves)
    max_score = 0
    max_direction = nil
    return [0, nil] if moves.nil? || moves.empty?

    moves.each do |direction, attrs|
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

