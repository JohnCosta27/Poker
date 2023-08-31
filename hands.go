package main

type Hand = int

const (
  HIGH_CARD Hand = iota
  PAIR
  TWO_PAIR
  THREE_OF_A_KIND
  STRAIGHT
  FLUSH
  FULL_HOUSE
  FOUR_OF_A_KIND
  STRAIGHT_FLUSH
  ROYAL_FLUSH
)

const HAND_LEN = 7

/**
 * Given 7 cards, what poker hand did you get.
 */
func GetHand() {
  
}

// ---------------------------------------------
// Helper Functions -> Assumes cards are sorted.
// ---------------------------------------------

func isRoyalFlush(SortedCards []Card) bool {
  panic("Not implemented")
}

// Straight Flush
// 
// Straight that in the same 5 cards is also a flush
// Code same as `isStraight` but with the type taken
// into account.
func isStraightFlush(SortedCards []Card) bool {
  return true
}

func isFourOfAKind(SortedCards []Card) bool {
  cardValueMap := make(map[int]int)

  for _, card := range SortedCards {
    _, ok := cardValueMap[int(card.Value)]
    if ok {
      cardValueMap[int(card.Value)] += 1
      continue
    }
    cardValueMap[int(card.Value)] = 1
  }

  for _, count := range cardValueMap {
    if count == 4 {
      return true
    }
  }
  
  return false
}

func isFullHouse(SortedCards []Card) bool {
  cardValueMap := make(map[int]int)

  for _, card := range SortedCards {
    _, ok := cardValueMap[int(card.Value)]
    if ok {
      cardValueMap[int(card.Value)] += 1
      continue
    }
    cardValueMap[int(card.Value)] = 1
  }

  threeOfAKind := false
  pair := false

  for _, count := range cardValueMap {
    if count == 3 {
      threeOfAKind = true
    } else if count == 2 {
      pair = true
    }
  }

  return threeOfAKind && pair
}

// Handles any number of cards
func isFlush(SortedCards []Card) bool {
  clubs := 0
  spades := 0
  diamonds := 0
  hearts := 0

  for _, card := range SortedCards {
    switch card.Type {
    case CLUB:
      clubs++
    case SPADE:
      spades++
    case DIAMOND:
      diamonds++
    case HEART:
      hearts++
    }
  }

  return clubs >= 5 || spades >= 5 || diamonds >= 5 || hearts >= 5
}

func isStraight(SortedCards []Card) bool {
  counter := 1

  //
  // Edge Case (A, 2, 3, 4 ,5)
  // IF there is an ace, and a two. We count it as a consequitive card.
  // 

  containsAce := SortedCards[HAND_LEN - 1].Value == ACE
  if (containsAce && SortedCards[0].Value == TWO) {
    counter++;
  }

  for i := 1; i < HAND_LEN; i++ {
    if (SortedCards[i - 1].Value < SortedCards[i].Value) {
      counter++;
    }
  }

  return counter >= 5;
}

func isThreeOfAKind(SortedCards []Card) bool {
  cardValueMap := make(map[int]int)

  for _, card := range SortedCards {
    _, ok := cardValueMap[int(card.Value)]
    if ok {
      cardValueMap[int(card.Value)] += 1
      continue
    }
    cardValueMap[int(card.Value)] = 1
  }

  for _, count := range cardValueMap {
    if count == 3 {
      return true
    }
  }
  
  return false
}

func isTwoPair(SortedCards []Card) bool {
  pairsCount := 0

  for i := 1; i < len(SortedCards); i++ {
    if (SortedCards[i - 1].Value == SortedCards[i].Value) {
      pairsCount++;
      i += 1;
    }
  }

  return pairsCount >= 2
}

func isPair(SortedCards []Card) bool {
  for i := 1; i < len(SortedCards); i++ {
    if (SortedCards[i - 1].Value == SortedCards[i].Value) {
      return true
    }
  }

  return false
}

func assert7Cards(Cards []Card) {
  if (len(Cards) != HAND_LEN) {
    panic("asset7Cards called without 7 cards")
  }
}

func assert5Cards(Cards []Card) {
  if (len(Cards) != 5) {
    panic("asset7Cards called without 7 cards")
  }
}
