require_relative '../spec_helper'

describe Piece do
  let(:piece1) { Piece.new(1) }

  it "should have a value" do
    piece1.value.should == 1
  end

  context "when piece value is 1" do
    let(:other_piece1) { Piece.new(1) }
    let(:piece2)       { Piece.new(2) }
    let(:piece3)       { Piece.new(3) }

    it "should not be able to combine with a non-2 piece" do
      piece1.merge_with(other_piece1).should be_false
      piece1.merge_with(piece3).should be_false
    end

    it "should be able to combine with a value of 2" do
      piece1.merge_with(piece2)
      piece1.value.should == 3
    end

    it "should not be worth any points" do
      piece1.points.should == 0
    end
  end

  context "when the piece value is 2" do
    let(:other_piece2) { Piece.new(2) }
    let(:piece2)       { Piece.new(2) }
    let(:piece3)       { Piece.new(3) }

    it "should not be able to combine with a non-2 piece" do
      piece2.merge_with(other_piece2).should be_false
      piece2.merge_with(piece3).should be_false
    end

    it "should be able to combine with a value of 1" do
      piece2.merge_with(piece1)
      piece2.value.should == 3
    end

    it "should not be worth any points" do
      piece2.points.should == 0
    end
  end

  context "when the piece value is 3 or greater" do
    let(:sequence) { [3, 6, 12, 24, 48, 96, 192, 384, 768, 1536] }

    it "should not merge with different numbers" do
      sequence.length.times do |i|
        piece = Piece.new(sequence[i])
        other_piece = Piece.new(sequence[i - 1])

        piece.merge_with(other_piece).should be_false
      end
    end

    it "should merge with a piece of the same value" do
      sequence.each do |x|
        piece = Piece.new(x)
        other_piece = Piece.new(x)

        piece.merge_with(other_piece)
        piece.value.should == x * 2
      end
    end

    it "should be able to be marked as wild" do
      piece = Piece.new
      expect {
        piece.wild!
      }.to change(piece, :wild?).to(true)
    end

    it "should be worth 1 point" do
      piece = Piece.new(3)
      piece.points.should == 3
    end
  end

  context "when the piece value is 6" do
    let(:piece2)       { Piece.new(2) }
    let(:piece3)       { Piece.new(3) }
    let(:piece6)       { Piece.new(6) }
    let(:other_piece6) { Piece.new(6) }

    it "should should not merge with non-6 pieces" do
      piece6.merge_with(piece3).should be_false
      piece6.merge_with(piece2).should be_false
      piece6.merge_with(piece1).should be_false
    end

    it "should merge with other 6 pieces" do
      piece6.merge_with(other_piece6)
      piece6.value.should == 12
    end

    it "should be worth 8 points" do
      piece6.points.should == 9
    end
  end
end

