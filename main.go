package main

import "fmt"

func main() {
  deck := DeckFactory()
  deck.Shuffle()

  fmt.Println(deck.Deal())
  fmt.Println(deck.Deal())
  fmt.Println(deck.Deal())
  fmt.Println(deck.Deal())
  fmt.Println(deck.Deal())
  fmt.Println(deck.Deal())
}
