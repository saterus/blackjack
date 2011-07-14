# Module     : Ruby Casino Blackjack
# Copyright  : Copyright (C) 2009 Alex Burkhart
# License    : WTFPL
# Maintainer : Alex Burkhart <anb19@case.edu>
# Tested In  : Ruby 1.8.7
#

require 'Card'

class Hand

  attr_reader :cards, :bet
  attr_accessor :count

  def initialize(hole_card, ante)
    @cards = [hole_card]
    @bet = ante
    @count = 0
    @aces = 0
    update_count(hole_card.count)
    self.class.build_recommendations
    self
  end

  # Adds a card to the hand and then updates the count.
  # Returns the count.
  def take(card)
    @cards << card
    update_count(card.count)
  end

  # Updates the count after recieving a new card.
  # The count assumes aces to be 11, unless the hand busts.
  # Returns the count.
  def update_count(val)
    if val == :A
      @aces = @aces + 1
      @count = @count + 11
    else
      @count = @count + val
    end
    @count = correct_for_aces
  end

  # Returns true if the count goes over 21.
  def busted?
    @count > 21
  end

  # Corrects the count if the hand busts with aces by counting
  # an ace as a soft ace.
  # Returns the count.
  def correct_for_aces
    if busted? && @aces > 0
      @aces = @aces - 1
      @count = @count - 10
    else
      @count
    end
  end

  # Returns true if both cards have the same face value.
  def pair?
    @cards.length == 2 && @cards[0].face_value == @cards[1].face_value
  end

  def soft?
    @aces > 0
  end

  def to_s
    @cards.join(", ")
  end

  # to_s, except the hole card remains hidden.
  def public_show
    @cards[1..-1].join(", ")
  end

  def public_count
    @cards[1].count
  end

  def size
    @cards.length
  end

  def double_down
    @bet *= 2
  end

  # Provides a statistical recommenation based on the player's situation and
  # the dealer's faceup card.
  def recommendation(dealer_count)
    if soft?
      if pair? #pair of aces
        @@pair_table[0][dealer_index(dealer_count)]
      else
        case non_ace_count
          when (8..10) then @@soft_table[0][dealer_index(dealer_count)]
          when 7       then @@soft_table[1][dealer_index(dealer_count)]
          when 6       then @@soft_table[2][dealer_index(dealer_count)]
          when (4..5)  then @@soft_table[3][dealer_index(dealer_count)]
          when (2..3)  then @@soft_table[4][dealer_index(dealer_count)]
        end
      end
    elsif pair?
      case @cards[0].count
        when 8     then @@pair_table[0][dealer_index(dealer_count)]
        when 10    then @@pair_table[1][dealer_index(dealer_count)]
        when 9     then @@pair_table[2][dealer_index(dealer_count)]
        when 2,3,7 then @@pair_table[3][dealer_index(dealer_count)]
        when 6     then @@pair_table[4][dealer_index(dealer_count)]
        when 5     then @@pair_table[5][dealer_index(dealer_count)]
        when 4     then @@pair_table[6][dealer_index(dealer_count)]
      end
    else #hard count
      case @count
        when (17..21) then @@hard_table[0][dealer_index(dealer_count)]
        when (13..16) then @@hard_table[1][dealer_index(dealer_count)]
        when 12       then @@hard_table[2][dealer_index(dealer_count)]
        when 11       then @@hard_table[3][dealer_index(dealer_count)]
        when 10       then @@hard_table[4][dealer_index(dealer_count)]
        when 9        then @@hard_table[5][dealer_index(dealer_count)]
        when (5..8)   then @@hard_table[6][dealer_index(dealer_count)]
      end
    end
  end

  # Pulls the non-ace count from a soft set of cards.
  def non_ace_count
    c = @count
    @aces.times{ c -= 11 }
    c
  end

  # Determines the index on the recommendation tables based on the
  # dealer's count.
  def dealer_index(dealer_count)
    if dealer_count == :A
      -1
    else
      dealer_count - 2
    end
  end

  # Recommendations are stored in lookup tables for easy reference.
  def self.build_recommendations
    # Dealer's Card   2   3   4   5   6   7   8   9  10   A / Your Card
    @@hard_table = [[:S, :S, :S, :S, :S, :S, :S, :S, :S, :S], #17-21
                    [:S, :S, :S, :S, :S, :H, :H, :H, :H, :H], #13-16
                    [:H, :H, :S, :S, :S, :H, :H, :H, :H, :H], #12
                    [:DH,:DH,:DH,:DH,:DH,:DH,:DH,:DH,:DH,:H], #11
                    [:DH,:DH,:DH,:DH,:DH,:DH,:DH,:DH,:H, :H], #10
                    [:H, :DH,:DH,:DH,:DH,:H, :H, :H, :H, :H], #9
                    [:H, :H, :H, :H, :H, :H, :H, :H, :H, :H]] #5-8

    # Dealer's Card   2   3   4   5   6   7   8   9  10   A / Your Card
    @@soft_table = [[:S, :S, :S, :S, :S, :S, :S, :S, :S, :S], #A/8, A/9, A/10
                    [:S, :DS,:DS,:DS,:DS,:S, :S, :H, :H, :H], #A/7
                    [:H, :DH,:DH,:DH,:DH,:H, :H, :H, :H, :H], #A/6
                    [:H, :H, :DH,:DH,:DH,:H, :H, :H, :H, :H], #A/4, A/5
                    [:H, :H, :H, :DH,:DH,:H, :H, :H, :H, :H]] #A/2, A/3

    # Dealer's Card   2   3   4   5   6   7   8   9  10   A / Your Card
    @@pair_table = [[:P, :P, :P, :P, :P, :P, :P, :P, :P, :P], #A/A, 8/8(16)
                    [:S, :S, :S, :S, :S, :S, :S, :S, :S, :S], #10/10(20)
                    [:P, :P, :P, :P, :P, :S, :P, :P, :S, :S], #9/9(18)
                    [:P, :P, :P, :P, :P, :P, :H, :H, :H, :H], #7/7(14), 3/3(6), 2/2(4)
                    [:P, :P, :P, :P, :P, :H, :H, :H, :H, :H], #6/6(12)
                    [:DH,:DH,:DH,:DH,:DH,:DH,:DH,:DH,:H, :H], #5/5(10)
                    [:H, :H, :H, :P, :P, :H, :H, :H, :H, :H]] #4/4(8)
  end

end
