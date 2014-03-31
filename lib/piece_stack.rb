class PieceStack < Array
  def refill!(max)
    if max >= 48
      if @include_wild.nil?
        @include_wild = false
      else
        @include_wild = !@include_wild
      end
    end
    if @include_wild
      wild = Piece.new(random_wild_value(max))
      wild.wild!
      self << wild
    end
    4.times do
      self << Piece.new(1)
    end
    4.times do
      self << Piece.new(2)
    end
    4.times do
      self << Piece.new(3)
    end

    self.shuffle!
  end

  private

  def random_wild_value(max)
    values = possible_random_values(max)
    values[rand(values.size)]
  end

  def possible_random_values(max)
    values = []
    value = max / 8

    while value > 3
      values << value
      value /= 2
    end

    return values
  end
end

