# Module     : Ruby Casino Blackjack
# Copyright  : Copyright (C) 2009 Alex Burkhart
# License    : WTFPL
# Maintainer : Alex Burkhart <anb19@case.edu>
# Tested In  : Ruby 1.8.7
#

require_relative 'Card'
require_relative 'Hand'

class Player

  # Convenience method for accessing the first hand (ie. dealer's hand).
  def hand
    hands[0]
  end
  attr_reader :name, :hands
  attr_accessor :wallet, :current_bet, :betting_unit, :min_bet

  def initialize(name)
    @name = name
    @hands = []
    @wallet = 1000.to_i       #kept giving 1000 as a float...
    @current_bet = 0
    @betting_unit = 0
    @min_bet = 0
  end

  # Adds a card to the indicated hand.
  # Returns the card added.
  def take(card, index=0)
    if @hands[index].nil?
      deal_hole card
    else
      @hands[index].take(card)
    end
    card
  end

  # Creates a new hand for the player.
  def deal_hole(card, bet=@current_bet)
    @hands << Hand.new(card, bet)
  end

  # Splits the indicated hand into two hands. One card remains in the
  # original hand, while the other is put into a new hand.
  # Each of the newly formed hands is given an additional card.
  # Returns the indices of the original hand and the new hand in an array.
  def split(index, a, b)
    deal_hole(@hands[index].cards.pop, @hands[index].bet)
    @hands[index].count -= @hands[-1].count
    take(a, index)
    take(b, @hands.length-1)
    [index, @hands.length-1]
  end

  # Discards the cards in the player's hands.
  # Returns the discarded cards in an array.
  def discard_hands
    discard = @hands
    @hands = []
    discard.inject([]){ |cards, h| cards + h.cards }
  end

  def to_s
    hands_str = (0...@hands.length).map{ |i| create_hand_str(i) }.join("\n")
    "#{@name}:  $#{@wallet}  ($#{sum_bets} in play)\n#{hands_str}"
  end

  # Returns a string with the details of the hand.
  def create_hand_str(index)
    "Hand #{index+1}:   Count: #{@hands[index].count}  -  (#{@hands[index]})"
  end

  # Returns the sum of all bets the player has on the table.
  def sum_bets
    @hands.inject(0){ |sum, hand| sum + hand.bet }
  end

end
