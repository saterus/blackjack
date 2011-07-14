# Module     : Ruby Casino Blackjack
# Copyright  : Copyright (C) 2009 Alex Burkhart
# License    : WTFPL
# Maintainer : Alex Burkhart <anb19@case.edu>
# Tested In  : Ruby 1.8.7
#

require 'Card'
require 'Hand'

# A shoe contains multiple decks of cards, shuffled and ready to use.
# The shoe tracks all cards yet unused and already discarded.
class Shoe

  attr_reader :count

  def initialize(num_decks)
    @contents = []
    @trash = []
    @count = 0
    @decks = num_decks
    num_decks.times{ (0..51).each{|n| @contents <<  Card.new(n) } }
    shuffle!
    burn
    self
  end

  # Shuffles all the unused cards in the shoe. Uses the
  # Fisher-Yates shuffling algorithm.
  # Returns nil.
  def shuffle!
    (@contents.size-1).downto(2) { |n|
      m = rand(n+1)
      @contents[n], @contents[m] = @contents[m], @contents[n]
    }
    nil
  end

  # Shuffles all the unused cards in the shoe.
  # Returns the newly shuffled shoe.
  def shuffle
    shuffle!
    self
  end

  # Shuffles all the unused cards and the discarded
  # cards together in the shoe.
  # Returns nil.
  def reshuffle!
    @contents << @trash
    @trash = []
    shuffle!
  end

  # Removes a card from the shoe and returns it.
  # Adjusts shoe count.
  def hit
    c = @contents.pop
    adjust_count c
    c
  end

  # Removes a card from the shoe and returns it.
  # Does not adjust the shoe count.
  def silent_hit
    @contents.pop
  end

  # Removes one card from the shoe and puts it directly into the trash.
  # Does not adjust the shoe count.
  # Returns the burnt card.
  def burn
    a = silent_hit
    @trash << a
    a
  end

  # Adds the cards within hands to the trash.
  # Returns the trash pile.
  def trash(cards)
    @trash += cards
  end

  def cards_left
    @contents.length
  end

  def to_s
    "#{@decks} decks. #{cards_left} cards remaining. #{@trash.length} cards in trash. #{( (52*@decks) - @contents.length - @trash.length)} cards in play."
  end

  def adjust_count(card)
    case card.count
      when :A    then @count -= 1
      when 10    then @count -= 2
      when 8,9   then @count
      when 2,3,7 then @count += 1
      when 4,5,6 then @count += 2
    end
  end

end
