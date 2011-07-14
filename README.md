# Blackjack at the Ruby Casino

Blackjack at the Ruby Casino is a small console based game of
Blackjack for multiple players. It includes both a Training Mode and a
Card Counting Mode.

## Usage

```ruby Blackjack.rb \[--t\] \[--c\]```

The ```--t``` argument enables Training Mode which will give you
hints on how best to play out your hand. You can test yourself before
revealing the hint to make sure you are improving.

The ```--c``` argument enables Card Counting Mode which tracks the
current **count** of the deck. Counting Mode details the counts it
uses for each range of cards and interally tracks the count. You can
compare notes against it to make sure you are correct.

## History

This game is a code sample I provided [Rapleaf](http://rapleaf.com) as part
of my interview in 2009. It is one of the first real Ruby projects I
wrote. Idiomatic Ruby it is not, but it I see no reason to correct
it. For being a code sample, the game is pretty good if I do say so myself.

I actually learned a great deal about playing Blackjack while I was writing
this. The Training Mode in particular is actually pretty good about
recommending strong plays. Maybe someday I'll write a bot to play
using only the Training Mode recommendations to see how it performs.

I remembered this existed and found my submission buried in my email. I left the original in tact when putting it up on Github. You can find
the exact original in the original-1.8.7 branch. I fixed the requires
for 1.9 which exists as the master branch.
