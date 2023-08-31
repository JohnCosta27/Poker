package main

import "testing"

func TestStraightFlush(t *testing.T) {
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

func TestUpperStraight(t *testing.T) {
  cards := []Card{
    {
      Value: TEN,
      Type: SPADE,
    },
    {
      Value: JACK,
      Type: SPADE,
    },
    {
      Value: QUEEN,
      Type: SPADE,
    },
    {
      Value: KING,
      Type: SPADE,
    },
    {
      Value: ACE,
      Type: SPADE,
    },
    {
      Value: THREE,
      Type: HEART,
    },
    {
      Value: THREE,
      Type: HEART,
    },
  }

  if (!isStraight(cards)) {
    t.Error("Should be a straight")
  }

}

func TestLowStraight(t *testing.T) {
  cards := []Card{
    {
      Value: TWO,
      Type: SPADE,
    },
    {
      Value: THREE,
      Type: HEART,
    },
    {
      Value: THREE,
      Type: DIAMOND,
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
      Value: ACE,
      Type: SPADE,
    },
  }

  if (!isStraight(cards)) {
    t.Error("Should be a straight")
  }

  if (!isFlush(cards)) {
    t.Error("Should be a flush")
  }
}
