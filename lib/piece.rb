class Piece
  attr_reader :value

  def initialize(value = nil)
    @value = value
    @wild = false
  end

  def self.rank_of(value)
    if value == 3
      1
    else
      1 + rank_of(value / 2)
    end
  end

  def merge_with(other_piece)
    return false unless self.can_merge?(other_piece)

    @value += other_piece.value
  end

  def can_merge?(other)
    if self.value == 1
      return other.value == 2
    elsif self.value == 2
      return other.value == 1
    else
      return other.value == self.value
    end
  end

  def wild!
    @wild = true
  end

  def wild?
    @wild
  end

  def ==(other)
    if other.nil?
      false
    elsif other.is_a?(Numeric)
      self.value == other
    else
      self.value == other.value
    end
  end

  def points
    if self.value < 3
      0
    else
      3 ** self.rank
    end
  end

  def rank
    self.class.rank_of(self.value)
  end

  def inspect
    self.value
  end
end

Pos = Struct.new(:x, :y)

