package main

import "testing"

func TestFlush(t *testing.T) {
  cards := []Card{
    {
      Value: TWO,
      Type: SPADE,
    },
    {
      Value: THREE,
      Type: SPADE,
    },
    {
      Value: FOUR,
      Type: SPADE,
    },
    {
      Value: FIVE,
      Type: SPADE,
    },
    {
      Value: SIX,
      Type: SPADE,
    },
    {
      Value: QUEEN,
      Type: HEART,
    },
    {
      Value: KING,
      Type: HEART,
    },
  }

  if (!isStraight(cards)) {
    t.Error("Should have been a straight")
  }

  if (!isFlush(cards)) {
    t.Error("Should have been a flush")
  }

  if (isThreeOfAKind(cards)) {
    t.Error("Should not have been a three of a kind")
  }

  if (!isStraightFlush(cards)) {
    t.Error("Should have been a straight flush")
  }

}
