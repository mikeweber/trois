require_relative '../spec_helper'
require 'trois_player'

describe TroisPlayer do
  let(:board)  { TroisBoard.new }
  let(:player) { TroisPlayer.new(board, true) }

  context "when all of the 1s are on the left half of the board" do
    # Start with the following board
    # +--+--+--+--+
    # |  |  | 3|  |
    # +--+--+--+--+
    # | 1|  | 6|  |
    # +--+--+--+--+
    # |  | 1| 3|  |
    # +--+--+--+--+
    # |  |  | 6|  |
    # +--+--+--+--+

    it "should not want to slide left when a 2 is next" do
      board.add_piece(Piece.new(1), Pos.new(0, 1))
      board.add_piece(Piece.new(1), Pos.new(1, 2))
      board.add_piece(Piece.new(3), Pos.new(2, 0))
      board.add_piece(Piece.new(6), Pos.new(2, 1))
      board.add_piece(Piece.new(3), Pos.new(2, 2))
      board.add_piece(Piece.new(6), Pos.new(2, 3))

      10.times do
        pp player.calculate_moves(board, 1) if player.best_move(1) == :left
        player.best_move(1).should_not == :left
      end
    end
  end

  context "when three 3s can be combined" do
    # Start with the following board
    # +--+--+--+--+
    # |48| 2| 6| 1|
    # +--+--+--+--+
    # | 3|12|  |  |
    # +--+--+--+--+
    # | 3|24| 2| 2|
    # +--+--+--+--+
    # | 3|  | 2| 2|
    # +--+--+--+--+

    it "should prefer the move that leaves a 6 next to a 12" do
      board.add_piece(Piece.new(48), Pos.new(0, 0))
      board.add_piece(Piece.new(2),  Pos.new(1, 0))
      board.add_piece(Piece.new(6),  Pos.new(2, 0))
      board.add_piece(Piece.new(1),  Pos.new(3, 0))

      board.add_piece(Piece.new(3),  Pos.new(0, 1))
      board.add_piece(Piece.new(12), Pos.new(1, 1))

      board.add_piece(Piece.new(3),  Pos.new(0, 2))
      board.add_piece(Piece.new(12), Pos.new(1, 2))
      board.add_piece(Piece.new(2),  Pos.new(2, 2))
      board.add_piece(Piece.new(2),  Pos.new(3, 2))

      board.add_piece(Piece.new(3),  Pos.new(0, 3))
      board.add_piece(Piece.new(2),  Pos.new(2, 3))
      board.add_piece(Piece.new(2),  Pos.new(3, 3))

      board.stub(:random_piece).and_return(Piece.new(2))

      player.best_move(2).should == :up
    end
  end

  context "when testing adjacencency" do
    context "when pieces are side by side" do
      before(:each) do
        board.add_piece(Piece.new(3), Pos.new(1, 1))
        board.add_piece(Piece.new(3), Pos.new(2, 1))
      end

      it "should be adjacent" do
        puts TroisBoardPrinter.new(board).print_board
        player.pieces_adjacent?(board, 3, 3).should be_true
      end
    end

    context "when pieces are above and below" do
      before(:each) do
        board.add_piece(Piece.new(3), Pos.new(1, 1))
        board.add_piece(Piece.new(3), Pos.new(1, 2))
      end

      it "should be adjacent" do
        player.pieces_adjacent?(board, 3, 3).should be_true
      end
    end

    context "when pieces are diagonal" do
      before(:each) do
        board.add_piece(Piece.new(3), Pos.new(2, 1))
        board.add_piece(Piece.new(3), Pos.new(1, 2))
      end

      it "should not be adjacent" do
        player.pieces_adjacent?(board, 3, 3).should be_false
      end
    end
  end

  context "when finding the best move" do
    it "should return the move with the highest score" do
      moves = { left: { scores: [10], moves: [] }, right: { scores: [15], moves: [] }, up: { scores: [7], moves: [] }, down: { scores: [20], moves:[] } }

      player.find_best_move(moves).should == [:down, 20]
    end

    it "should return the move with the highest average score" do

      moves = { left: { scores: [10, 20], moves: [] }, right: { scores: [25, 29], moves: [] }, up: { scores: [7, 17], moves: [] }, down: { scores: [20, 30], moves:[] } }

      player.find_best_move(moves).should == [:right, 27]
    end

    it "should return a move when a child node has a higher average" do
      moves = {
        left:  { scores: [10, 20], moves: [] },
        right: { scores: [25, 29], moves: [] },
        up:    { scores: [7,  17], moves: [
          {
            left:  { scores: [50], moves: [] },
            right: { scores: [10], moves: [] }
          }
        ]},
        down:  { scores: [20, 30], moves: []}
      }

      player.find_best_move(moves).should == [:up, 50]
    end
  end
end

