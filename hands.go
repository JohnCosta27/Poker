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

/**
 * Given 7 cards, what poker hand did you get.
 */
func GetHand() {
  
}

// ---------------------------------------------
// Helper Functions -> Assumes cards are sorted.
// ---------------------------------------------

func isStraightFlush(SortedCards []Card) bool {
  assert7Cards(SortedCards)

  return isStraightHelper(SortedCards[0:5]) && isFlush(SortedCards[0:5]) ||
    isStraightHelper(SortedCards[1:6]) && isFlush(SortedCards[1:6]) ||
    isStraightHelper(SortedCards[2:7]) && isFlush(SortedCards[2:7])
}

func isFourOfAKind(SortedCards []Card) bool {
  assert7Cards(SortedCards)

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
  assert7Cards(SortedCards)
  return isStraightHelper(SortedCards[0:5]) || 
    isStraightHelper(SortedCards[1:6]) || 
    isStraightHelper(SortedCards[2:7])
}

func isStraightHelper(SortedCards []Card) bool {
  assert5Cards(SortedCards)

  return SortedCards[0].Value == SortedCards[1].Value - 1 && 
    SortedCards[1].Value == SortedCards[2].Value - 1 && 
    SortedCards[2].Value == SortedCards[3].Value - 1 && 
    SortedCards[3].Value == SortedCards[4].Value - 1 
}

func isThreeOfAKind(SortedCards []Card) bool {
  assert7Cards(SortedCards)

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

func assert7Cards(Cards []Card) {
  if (len(Cards) != 7) {
    panic("asset7Cards called without 7 cards")
  }
}

func assert5Cards(Cards []Card) {
  if (len(Cards) != 5) {
    panic("asset7Cards called without 7 cards")
  }
}
