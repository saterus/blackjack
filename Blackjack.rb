# Module     : Ruby Casino Blackjack
# Copyright  : Copyright (C) 2009 Alex Burkhart
# License    : WTFPL
# Maintainer : Alex Burkhart <anb19@case.edu>
# Tested In  : Ruby 1.8.7
#

require_relative 'Shoe'
require_relative 'Hand'
require_relative 'Card'
require_relative 'Player'

class Blackjack

  def initialize
    set_mode
    @table_minimum = 100

    welcome_message

    add_players
    @shoe = Shoe.new(4)
    @dealer = Player.new(:Dealer)

    game_loop
  end

  # The game begins. The game loops until the players no longer
  # wish to play or they run out of money.
  def game_loop
    again = true

    while again
      bet
      deal
      player_action
      dealer_action
      reveal_final_hand
      print_player_outcomes
      remove_players

      again = play_again?
      linebreak
    end

    exit_message

  end

  # Adds players to the game by collecting name and betting info.
  def add_players
    player_count = get_int_input "How many players will there be? "
    return add_players if player_count <= 0

    @players = Array.new(player_count)
    player_count.times{ |i|
      print "Player #{i+1}, enter your name: "
      name = gets.strip.capitalize
      @players[i] = Player.new(name)
      collect_betting_unit(@players[i]) if $Counting_Mode
    }
    linebreak
  end

  # Initiates betting around the table.
  def bet
    if $Counting_Mode
      puts shoe_count
      puts counting_recommendation
      linebreak
    end
    @players.each{ |p|
      individual_bet(p)
    }
  end

  # Collects the bet for a player for the round.
  def individual_bet(player)
    if $Counting_Mode
      print counting_recommended_bet(player)
      print "You have $#{player.wallet}. "
    else
      print "#{player.name}, you have $#{player.wallet}. "
    end

    bet = get_int_input "How much would you like to wager? $"

    if bet < @table_minimum
      linebreak
      puts "You must bet at least the minimum bid of $#{@table_minimum}."
      individual_bet(player)
    elsif bet > player.wallet
      linebreak
      puts "You cannot bet more than you have left in your wallet."
      individual_bet(player)
    else
      player.wallet -= bet
      player.current_bet = bet
    end
  end

  # Card Counting Mode collects player minimum and maximum bets and uses
  # them to calculate a recommended bid amount.
  def collect_betting_unit(player)
    puts "For proper card counting recommendations, we need your betting preferences."

    min = get_int_input "Enter your minimum bid: $"

    if min < @table_minimum
      puts "You must bet at least the minimum bid of $#{@table_minimum}."
      return collect_betting_unit(player)
    end
    player.min_bet = min

    max = get_int_input "Enter your maximum bid: $"
    unit = (max - min) / 10
    player.betting_unit = unit

    puts "Your minimum bet is $#{min}. Your betting unit is $#{unit}."
    linebreak
  end

  # Deals cards to each player and the dealer.
  def deal
    @players.each{ |p| @shoe.trash(p.discard_hands) }
    @shoe.trash(@dealer.discard_hands)
    @shoe.reshuffle! if @shoe.cards_left < (@players.length+1) * 5
    first = true
    2.times{
      @players.each{ |p| p.take(@shoe.hit) }
      if first
        @dealer.take(@shoe.silent_hit)
      else
        @dealer.take(@shoe.hit)
      end
      first = false
    }

    # In Counting Mode, it'd be nice to see everyone's hand so you can practice
    # doing the count yourself. In other modes, it just clutters things though.
    all_player_status if $Counting_Mode
  end

  # Each player has an opportunity to perform an action during each round.
  # If they hit or split, they may end up performing multiple actions.
  def player_action
    @players.each{ |p|
      linebreak('-')
      p.hands.each_with_index{ |hand, index|
        hit  = true
        double = p.wallet >= hand.bet
        while hit
          splittable = hand.pair? && p.wallet >= hand.bet
          status(p)
          hit, split = player_decision(p, hand, index, double, splittable)
          double = false unless split
          linebreak
        end
      }
    }
  end

  # Performs the desired action based on player input.
  # Resplits allowed (including aces). Doubling after splits allowed.
  # Players playing in Card Counting Mode or Training Mode can access
  # additional menu items.
  # Return true if the player should make another choice for this hand.
  def player_decision(player, hand, hand_index, double, split)
    puts "#{player.name}, your options for Hand #{hand_index+1}:"
    puts "  H: Hit"
    puts "  S: Stand"
    puts "  D: Double Down" if double
    puts "  P: Split the Pair" if split
    puts "  T: Training Mode Recommendation" if $Training_Mode
    puts "  C: Card Counting Mode Recommendation" if $Counting_Mode
    puts "  #{shoe_count}" if $Counting_Mode
    print "Your choice? "
    choice = gets.strip.downcase.take(1)
    linebreak

    if "h" == choice   # Hit
      puts "The dealer gives you a #{player.take(@shoe.hit, hand_index)}."
      !busted? hand
    elsif "s" == choice   # Stand
      false
    elsif "d" == choice   # Double Down
      player.wallet -= hand.bet
      hand.double_down
      puts "The dealer gives you a #{player.take(@shoe.hit, hand_index)}."
      busted? hand
      false
    elsif "p" == choice   # Split
      player.wallet -= hand.bet
      puts "The dealer splits you into:"
      player.split(hand_index, @shoe.hit, @shoe.hit)
    elsif "t" == choice && $Training_Mode   # Training Hint
      puts training_recommendation(hand, double, split)
      linebreak
      player_decision(player, hand, hand_index, double, split)
    elsif "c" == choice && $Counting_Mode   # Counting Hint
      puts counting_recommendation
      linebreak
      player_decision(player, hand, hand_index, double, split)
    else   # Invalid
      puts "Selection not recognized. Please try again."
      player_decision(player, hand, hand_index, double, split)
    end
  end

  # Prints and returns true if the hand busted.
  def busted?(hand)
    if hand.busted?
      puts "Busted!"
      true
    else
      false
    end
  end

  # Determines the recommendation for a player in Training Mode.
  def training_recommendation(hand, double, split)
    rec = hand.recommendation(@dealer.hand.public_count)
    if :H == rec
      "You should probably hit."
    elsif :S == rec
      "You might want to stand."
    elsif :P == rec && split
      "Splitting would be wise."
    elsif :P == rec # && !split
      "Splitting would be wise, if you could afford a second hand. You're on your own for this one."
    elsif :DH == rec && double
      "Definitely double down."
    elsif :DH == rec # && !double
      "You should probably hit."
    elsif :DS == rec && double
      "Definitely double down."
    elsif :DS == rec # && !double
      "You might want to stand."
    else
      "There was an error calculating the recommendation."
    end
  end

  # Formats the shoe count as a string.
  def shoe_count
    count = @shoe.count
    positive = count >= 0
    "Current Deck Count: #{positive ? "+" : "-"}#{count.abs}"
  end

  # Determines the recommendation for a player in Counting Mode.
  def counting_recommendation
    count = @shoe.count
    if count <= 1
      @cold
    elsif count <= 10
      @warm
    else
      @hot
    end
  end

  # Determines the recommended bet for a player in Counting Mode.
  def counting_recommended_bet(player)
    count = @shoe.count
    if count <= 1
      bet = player.min_bet
    elsif count <= 10
      bet = player.min_bet + player.betting_unit * count
    else
      bet = player.min_bet + player.betting_unit * 10 + (player.betting_unit * (count/3))
    end
    "#{player.name}, your recommended bet is $#{bet}. "
  end

  # The dealer hits up to 17 and then stops.
  def dealer_action
    # Dealer stands on soft 17's.
    while @dealer.hand.count < 17
      @dealer.take(@shoe.hit)
    end

    # The first card is drawn silently. This fixes the count.
    @shoe.adjust_count(@dealer.hand.cards[0])
  end

  # Print outcome of each hand for each player.
  def print_player_outcomes
    @players.each{ |p|
      puts "#{p.name}:"
      p.hands.each_with_index{ |h, i|
        print "Hand #{i+1}: "
        eval_hand(p, h)
      }
      puts "#{p.name} total: $#{p.wallet}"
      linebreak
    }
  end

  # Evaluates the outcome of the player hand against the dealer hand.
  def eval_hand(player, player_hand)
    d = @dealer.hand.count
    p = player_hand.count

    if p > 21 || (d > p && d <= 21)   # LOSE!
      puts "You lost $#{player_hand.bet}."
    elsif d == p   # PUSH!
      player.wallet += player_hand.bet
      puts :Push
    elsif p == 21 && player_hand.size == 2   # BLACKJACK!
      # Blackjack pays out 3/2.
      player.wallet += (player_hand.bet*2.5).to_i
      puts "You won $#{player_hand.bet*1.5}!"
    else   # WIN!
      player.wallet += (player_hand.bet*2)
      puts "You won $#{player_hand.bet}!"
    end
  end

  # Remove players with no money left to bet.
  def remove_players
    @players, broke_players = @players.partition{ |p| p.wallet >= @table_minimum }
    broke_players.each{ |p|
      puts "#{p.name}, you no longer have enough money to meet the table minimum. Better luck next time."
      linebreak
    }
  end

  # Decide whether or not to play another hand.
  def play_again?
    if @players.empty?
      false
    else
      player_names = @players.map{ |p| p.name }.join(", ")
      print "#{player_names}, one more game (y/n)? "
      gets.strip.downcase.take(1) == "y"
    end
  end

  # Prints the player hands, the dealer's faceup cards, and the shoe.
  def status(player)
    puts player
    linebreak
    puts "Dealer showing #{@dealer.hand.public_show}"
    linebreak
  end

  # Prints all player's hands, and the dealer's faceup cards.
  def all_player_status
    linebreak
    @players.each{ |p| puts p; linebreak; }
    puts "Dealer showing #{@dealer.hand.public_show}"
    linebreak
  end

  # Prints the full hands at the end of each round.
  def reveal_final_hand
    linebreak('-')
    @players.each{ |p| puts p; linebreak; }
    puts "Dealer reveals #{@dealer.hand}. #{@dealer.hand.count}!"
    puts "Dealer BUSTED!" if @dealer.hand.busted?
    linebreak
  end

  # Prints a line break.
  def linebreak(char='')
    puts "#{char*50}"
  end

  def welcome_message
    linebreak
    puts "Welcome to the Ruby Casino!"
    puts "Our Blackjack tables are the finest in the world. Dealers stand on soft 17's, resplitting and doubling after splitting allowed. Blackjack payouts are 3/2. Our table minimum is $#{@table_minimum}."
    linebreak
    card_counting_rules if $Counting_Mode
  end

  def card_counting_rules
    puts "The Card Counting system the computer employs tracks the 'count' of the deck. The basic idea is that if the remaining cards in the shoe are high cards, you have good odds to get a blackjack or to have the dealer bust. When the deck is hot, the more you should bet. Back off if the deck cools and is mostly low cards. If you can manage to master this system, you might just be able to make it big in Vegas!"
    linebreak
    puts "Each time the dealer deals a card, you need to adjust your count. The computer uses the Zen Counting System. 2's, 3's, and 7's add +1 to the count. 4's, 5's, and 6's add +2 to the count. 8's and 9's are neutral. 10's, Jacks, Queens, and King's all reduce the count by -2. Aces subtract -1 from the count. Memorize this. Try to keep up!"
    linebreak
  end

  # Shows the player the end result of the game.
  def exit_message
    linebreak
    @players.each{ |p|
      result = p.wallet - 1000
      outcome = result >= 0 ? "richer" : "poorer"
      puts "#{p.name}, you walked away $#{result.abs} #{outcome}."
      puts "Final take: $#{p.wallet}"
      linebreak
    }

    puts "Thank you for playing Blackjack at the Ruby Casino!"
    puts "You may want to consider hiring me for a summer internship at Rapleaf."
    puts "Copyright 2009 Alex Burkhart."
  end

  # Get an integer input from the player, and asks them a second time
  # if they failed the first time. Or the second.
  def get_int_input(message)
    print message
    x = gets.strip
    if x.number?
      x.to_i
    else
      return get_int_input(message)
    end
  end

  # Turns on Card Counting Mode and Training Mode.
  # Either, both, or neither can be on at the same time.
  def set_mode
    $Counting_Mode = getopts("c")
    $Training_Mode = getopts("t")
    empty_argv
    set_counting_recommendation_strings if $Counting_Mode
  end

  # Detects the presence of command line arguments.
  def getopts(opt)
    ARGV.index("--#{opt}")
  end

  # Empties ARGV so that the standard 'gets' method works correctly.
  def empty_argv
    ARGV.length.times{ ARGV.pop }
  end

  # Creates reusable strings for displaying the meaning of a count range.
  def set_counting_recommendation_strings
    @cold = "The deck is cold. Play conservatively. There are more low cards than high cards. The dealer is less likely to bust, but so are you. Doubling down will be less useful. Blackjacks are less common."
    @warm = "The deck is warm. There are more high cards than low cards. Blackjacks will be common. Doubling down when appropriate will be advantagous. The dealer is likely to bust."
    @hot = "The deck is hot! Your biggest worry at this point is the dealer stealing your Blackjacks. This deck is stacked!"
  end

end

class String

  # Returns the first n characters of the string.
  # Similar to Haskell's Data.List.take function.
  def take(n)
    if n <= 0
      ""
    elsif self.length > n
      self[0,n]
    else
      self
    end
  end

  def number?
    self =~ /^\d*$/
  end
end

if __FILE__ == $0
  Blackjack.new
end
