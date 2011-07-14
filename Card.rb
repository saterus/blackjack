# Module     : Ruby Casino Blackjack
# Copyright  : Copyright (C) 2009 Alex Burkhart
# License    : WTFPL
# Maintainer : Alex Burkhart <anb19@case.edu>
# Tested In  : Ruby 1.8.7
#

class Card

  def initialize(seed)
    @value = seed
  end

  def face_value
   case @value % 13
     when 0 then :Ace
     when 12 then :King
     when 11 then :Queen
     when 10 then :Jack
     else (@value % 13) + 1
   end
  end

  def suit
   case @value / 13
     when 0 then :Clubs
     when 1 then :Diamonds
     when 2 then :Hearts
     else :Spades
   end
  end

  def count
    v = @value % 13
    if v == 0
      :A
    elsif v >= 9
      10
    else
      v + 1
    end
  end

  def to_s
   "#{face_value} of #{suit}"
  end

end
