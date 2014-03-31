require_relative '../spec_helper'

module TroisBoardSpecHelper
  def number_of_pieces(board)
    board.pieces.inject(0) do |sum, row|
      row.inject(sum) do |rsum, piece|
        piece ? rsum + 1 : rsum
      end
    end
  end
end

describe TroisBoard do
  include TroisBoardSpecHelper

  let(:board) { TroisBoard.new }

  it "should default to a 4x4 grid" do
    board.cols.should == 4
    board.rows.should == 4
  end

  it "should be able to add pieces to the board" do
    piece = Piece.new(3)
    pos = Pos.new(0, 1)

    expect {
      board.add_piece(piece, pos)
    }.to change { board.pieces[pos.x][pos.y] }.from(nil)
  end

  it "should be able to randomly place pieces" do
    piece_list = [Piece.new(1), Piece.new(1), Piece.new(2), Piece.new(2), Piece.new(3), Piece.new(3)]
    expect {
      board.randomly_add_pieces(piece_list)
    }.to change { number_of_pieces(board) }.by(piece_list.size)
  end

  it "should not be able to add a piece to an out of bounds position" do
    out_of_bounds_moves = [
      too_far_right = Pos.new( 4,  0),
      too_far_left  = Pos.new(-1,  0),
      too_far_up    = Pos.new( 0, -1),
      too_far_down  = Pos.new( 0,  4),
      left_field    = Pos.new(-4, 17)
    ]
    piece = Piece.new(3)

    out_of_bounds_moves.each do |pos|
      expect { board.add_piece(piece, pos).should be_false }.to_not change { number_of_pieces(board) }
    end
  end

  context "when merging pieces" do
    # Start with the following board
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | |3| |
    # +-+-+-+-+

    let(:board)  { TroisBoard.new }
    let(:piece1) { Piece.new(3) }
    let(:piece2) { Piece.new(3) }

    before(:each) do
      board.add_piece(piece1, Pos.new(2, 3))
    end

    it "should be merge pieces when mergeable pieces are placed together" do
      expect {
        board.add_piece(piece1, Pos.new(2, 3))
      }.to change { board.piece_at(Pos.new(2, 3)).value }.from(3).to(6)
    end
  end

  context "when sliding pieces temporarily" do
    # Start with the following board
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | |1| | |
    # +-+-+-+-+
    # | |2|3| |
    # +-+-+-+-+
    # | | |3| |
    # +-+-+-+-+

    let(:board) { TroisBoard.new }

    before(:each) do
      board.add_piece(Piece.new(1), Pos.new(1, 1))
      board.add_piece(Piece.new(2), Pos.new(1, 2))
      board.add_piece(Piece.new(3), Pos.new(2, 2))
      board.add_piece(Piece.new(3), Pos.new(2, 3))
    end

    it "should be able to slide pieces up" do
      new_board = nil
      expect {
        new_board = board.slide_up
      }.to_not change {
        board.pieces.inject(0) do |sum, row|
          row.inject(sum) do |rsum, piece|
            piece ? rsum + 1 : rsum
          end
        end
      }

      new_board.piece_at(Pos.new(1, 0)).value.should == 1
      new_board.piece_at(Pos.new(1, 1)).value.should == 2
      new_board.piece_at(Pos.new(2, 1)).value.should == 3
      new_board.piece_at(Pos.new(2, 2)).value.should == 3
    end

    it "should be able to slide pieces left" do
      new_board = nil
      expect {
        new_board = board.slide_left
      }.to_not change {
        board.pieces.inject(0) do |sum, row|
          row.inject(sum) do |rsum, piece|
            piece ? rsum + 1 : rsum
          end
        end
      }

      new_board.piece_at(Pos.new(0, 1)).value.should == 1
      new_board.piece_at(Pos.new(0, 2)).value.should == 2
      new_board.piece_at(Pos.new(1, 2)).value.should == 3
      new_board.piece_at(Pos.new(1, 3)).value.should == 3
    end

    it "should be able to slide pieces right" do
      new_board = nil
      expect {
        new_board = board.slide_right
      }.to_not change {
        board.pieces.inject(0) do |sum, row|
          row.inject(sum) do |rsum, piece|
            piece ? rsum + 1 : rsum
          end
        end
      }

      new_board.piece_at(Pos.new(2, 1)).value.should == 1
      new_board.piece_at(Pos.new(2, 2)).value.should == 2
      new_board.piece_at(Pos.new(3, 2)).value.should == 3
      new_board.piece_at(Pos.new(3, 3)).value.should == 3
    end

    it "should combine pieces when sliding pieces down" do
      new_board = nil
      expect {
        new_board = board.slide_down
      }.to_not change {
        board.pieces.inject(0) do |sum, row|
          row.inject(sum) do |rsum, piece|
            piece ? rsum + 1 : rsum
          end
        end
      }

      new_board.piece_at(Pos.new(1, 2)).value.should == 1
      new_board.piece_at(Pos.new(1, 3)).value.should == 2
      new_board.piece_at(Pos.new(2, 3)).value.should == 6
    end
  end

  context "when determing available moves" do
    # Start with the following board
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | |3| |
    # +-+-+-+-+
    # | | |1| |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+

    let(:board) { TroisBoard.new }

    before(:each) do
      board.add_piece(Piece.new(3), Pos.new(2, 1))
      board.add_piece(Piece.new(1), Pos.new(2, 2))
    end

    it "should allow 4 directional movement" do
      board.available_moves.should =~ [:left, :right, :up, :down]
    end

    it "should know when it can't move" do
      expect {
        board.add_piece(Piece.new(2), Pos.new(2, 0))
      }.to change(board, :can_move_up?).from(true).to(false)
      board.available_moves.should =~ [:left, :right, :down]
    end
  end

  context "after a confirmed move down" do
    # Start with the following board
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | |3| |
    # +-+-+-+-+
    # | | |1| |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+

    let(:board) { TroisBoard.new }

    before(:each) do
      reset_board
    end

    def reset_board
      board.clear!
      board.add_piece(Piece.new(3), Pos.new(2, 1))
      board.add_piece(Piece.new(1), Pos.new(2, 2))
    end

    it "should become permanent" do
      board.slide_down!

      board.piece_at(Pos.new(2, 2)).value.should == 3
      board.piece_at(Pos.new(2, 3)).value.should == 1
    end

    it "should add a piece in the column that moved" do
      # confirm that it isn't random
      10.times do
        expect {
          board.slide_down!
        }.to change { board.piece_at(Pos.new(2, 0)) }.from(nil)
        reset_board
      end
    end

    it "should find that 2 columns moved when another piece is added" do
      board.add_piece(Piece.new(3), Pos.new(1, 1))
      slid_down = board.slide_down
      moved_columns = board.send(:moved_columns, slid_down)
      moved_columns =~ [1, 2]
    end

    it "should not add a piece when when a move results in no change" do
      board.add_piece(Piece.new(2), Pos.new(2, 0))
      expect {
        board.slide_up!
      }.to_not change(board, :size)
    end

    it "should only combine threes that exist before the move" do
      board.add_piece(Piece.new(2), Pos.new(2, 3))
      expect {
        board.slide_down!
        # raise board.inspect
      }.to_not change(board, :size)
      board.piece_at(Pos.new(2, 3)).value.should == 3
      board.piece_at(Pos.new(2, 2)).should_not be_nil
      board.piece_at(Pos.new(2, 2)).value.should == 3
      board.piece_at(Pos.new(2, 1)).should be_nil
      board.piece_at(Pos.new(2, 0)).should_not be_nil
    end
  end

  context "after a confirmed move left" do
    # Start with the following board
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | |1|3| |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+
    # | | | | |
    # +-+-+-+-+

    let(:board) { TroisBoard.new }

    before(:each) do
      reset_board
    end

    def reset_board
      board.clear!
      board.add_piece(Piece.new(1), Pos.new(1, 1))
      board.add_piece(Piece.new(3), Pos.new(2, 1))
    end

    it "should become permanent" do
      board.slide_left!

      board.piece_at(Pos.new(0, 1)).should == 1
      board.piece_at(Pos.new(1, 1)).should == 3
    end

    it "should add a piece in the row that moved" do
      # confirm that the placement isn't random
      10.times do
        expect {
          board.slide_left!
        }.to change { board.piece_at(Pos.new(3, 1)) }.from(nil)
        reset_board
      end
    end

    it "should find that 2 rows moved when another piece is added" do
      board.add_piece(Piece.new(3), Pos.new(1, 0))
      slid_left = board.slide_left
      moved_columns = board.send(:moved_columns, slid_left)
      moved_columns =~ [0, 1]
    end

    it "should only combine threes that exist before the move" do
      board.add_piece(Piece.new(2), Pos.new(0, 1))
      expect {
        board.slide_left!
      }.to_not change(board, :size)
      board.piece_at(Pos.new(0, 1)).value.should == 3
      board.piece_at(Pos.new(1, 1)).should_not be_nil
      board.piece_at(Pos.new(1, 1)).value.should == 3
      board.piece_at(Pos.new(2, 1)).should be_nil
      board.piece_at(Pos.new(3, 1)).should_not be_nil
    end
  end

  context "when there are no more available moves" do
    # Start with the following board
    # +-+-+-+-+
    # |1|3|1|3|
    # +-+-+-+-+
    # | |3|1|3|
    # +-+-+-+-+
    # |1|3|1|3|
    # +-+-+-+-+
    # |3|1|3|1|
    # +-+-+-+-+

    let(:board) { TroisBoard.new }

    before(:each) {
      fill_board
      board.stub(:random_piece).and_return(Piece.new(2))
    }

    def fill_board
      board.add_piece(Piece.new(1), Pos.new(0, 0))
      board.add_piece(Piece.new(3), Pos.new(1, 0))
      board.add_piece(Piece.new(1), Pos.new(2, 0))
      board.add_piece(Piece.new(3), Pos.new(3, 0))

      board.add_piece(Piece.new(3), Pos.new(1, 1))
      board.add_piece(Piece.new(1), Pos.new(2, 1))
      board.add_piece(Piece.new(3), Pos.new(3, 1))

      board.add_piece(Piece.new(1), Pos.new(0, 2))
      board.add_piece(Piece.new(3), Pos.new(1, 2))
      board.add_piece(Piece.new(1), Pos.new(2, 2))
      board.add_piece(Piece.new(3), Pos.new(3, 2))

      board.add_piece(Piece.new(3), Pos.new(0, 3))
      board.add_piece(Piece.new(1), Pos.new(1, 3))
      board.add_piece(Piece.new(3), Pos.new(2, 3))
      board.add_piece(Piece.new(1), Pos.new(3, 3))
    end

    it "should be game over" do
      expect {
        board.slide_left!
      }.to change(board, :playing?).from(true).to(false)
    end

    it "should know how to total the points" do
      board.points.should == 24
    end
  end
end

