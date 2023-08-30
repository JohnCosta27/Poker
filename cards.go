package main

import (
	"math/rand"
)

type CardValue int
type CardType int

const (
  TWO CardValue = iota
  THREE
  FOUR
  FIVE
  SIX
  SEVEN
  EIGHT
  NINE
  TEN
  JACK
  QUEEN
  KING
  ACE
)

func (v CardValue) String() string {
  return [...]string{
  "Ace",
  "Two",
  "Three",
  "Four",
  "Five",
  "Six",
  "Seven",
  "Eight",
  "Nine",
  "Ten",
  "Jack",
  "Queen",
  "King",
  }[v]
}

const (
  SPADE CardType = iota
  CLUB
  DIAMOND
  HEART
)

func (t CardType) String() string {
  return [...]string{
  "Spade",
  "Club",
  "Diamond",
  "Heart",
  }[t]
}

type Card struct {
  Value CardValue
  Type CardType
}

type Deck struct {
  Cards []Card
  Used int
}

func DeckFactory() Deck {
  d := Deck{}

  d.Cards = make([]Card, 0)
  d.Used = 0

  d.Cards = append(d.Cards, Card{
    Value: ACE,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: TWO,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: THREE,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: FOUR,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: FIVE,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: SIX,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: SEVEN,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: EIGHT,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: NINE,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: TEN,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: JACK,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: QUEEN,
    Type: SPADE,
  })
  d.Cards = append(d.Cards, Card{
    Value: KING,
    Type: SPADE,
  })

  d.Cards = append(d.Cards, Card{
    Value: ACE,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: TWO,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: THREE,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: FOUR,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: FIVE,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: SIX,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: SEVEN,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: EIGHT,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: NINE,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: TEN,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: JACK,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: QUEEN,
    Type: CLUB,
  })
  d.Cards = append(d.Cards, Card{
    Value: KING,
    Type: CLUB,
  })

  d.Cards = append(d.Cards, Card{
    Value: ACE,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: TWO,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: THREE,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: FOUR,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: FIVE,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: SIX,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: SEVEN,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: EIGHT,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: NINE,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: TEN,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: JACK,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: QUEEN,
    Type: DIAMOND,
  })
  d.Cards = append(d.Cards, Card{
    Value: KING,
    Type: DIAMOND,
  })

  d.Cards = append(d.Cards, Card{
    Value: ACE,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: TWO,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: THREE,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: FOUR,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: FIVE,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: SIX,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: SEVEN,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: EIGHT,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: NINE,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: TEN,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: JACK,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: QUEEN,
    Type: HEART,
  })
  d.Cards = append(d.Cards, Card{
    Value: KING,
    Type: HEART,
  })

  return d
}

func (d Deck) Shuffle() {
  for i := 0; i < len(d.Cards) - 2; i++ {
    random := i + rand.Intn(52 - i)

    temp := d.Cards[i]
    d.Cards[i] = d.Cards[random]
    d.Cards[random] = temp
  }
}

func (d *Deck) Deal() Card {
  d.Used += 1
  return d.Cards[d.Used - 1]
}
