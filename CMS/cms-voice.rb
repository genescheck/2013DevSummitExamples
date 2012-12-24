ask "Hello World, Please say a number between one and ten.", {
  :choices => "number(one, two, three, four, five, six, 
    seven, eight, nine, ten)",
  :onChoice => lambda { |event|
    say("The " + event.value + " you chose is " + 
      event.choice.interpretation + ". Thank you, Goodbye")   
  }
}
hangup
