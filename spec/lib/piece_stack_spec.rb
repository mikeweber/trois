require_relative '../spec_helper'

describe PieceStack do
  let(:stack) { PieceStack.new }

  it "should start empty" do
    stack.should be_empty
  end

  it "should be able to refill itself" do
    expect {
      stack.refill!(6)
    }.to change { stack.size }.from(0).to(12)
  end

  it "should be equal parts 1s, 2s and 3s" do
    stack.refill!(6)
    stack.select { |piece| piece.value == 1 }.size.should == 4
    stack.select { |piece| piece.value == 2 }.size.should == 4
    stack.select { |piece| piece.value == 3 }.size.should == 4
  end

  context "when the max card on the board is 24 or less" do
    it "should never include a wild card" do
      10.times do
        stack.refill!(24)
        stack.size.should == 12
        stack.should_not be_any { |piece| piece.wild? }
        12.times { stack.pop }
      end
    end
  end

  context "when the max card on the board is 48 or greater" do
    it "should include a wildcard every other refill" do
      stack.refill!(48)
      stack.size.should == 12
      stack.should_not be_any { |piece| piece.wild? }
      12.times { stack.pop }
      stack.should be_empty

      stack.refill!(48)
      stack.size.should == 13
      stack.select { |piece| piece.wild? }.size.should == 1
      13.times { stack.pop }
      stack.should be_empty

      stack.refill!(48)
      stack.should_not be_any { |piece| piece.wild? }
      stack.size.should == 12
    end
  end
end

