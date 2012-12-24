call ('sip:mtv969@sip2sip.info'), {
  :allowSignals => "exit",
  :onAnswer => lambda {
    say "Hello World, please hold"
    say "https://raw.github.com/ds2222/SampleCode/master/CES/music.mp3"
    say "Thanks for holding. Goodbye"
  }
}
hangup
