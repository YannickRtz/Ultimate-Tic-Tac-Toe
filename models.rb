class Games < ActiveRecord::Base
  
end

=begin

Tabellenstruktur:
id, p1name, p2name, p1hash, p2hash, p1last, p2last, p1haspw, p2haspw,
started, whoseturn, bigfield, fields

Inhalte des JSON-Strings:
- Welcher Spieler ist an der Reihe?
- Welche kleinen Felder haben welche Farbe?
- Welche großen Felder haben welche Farbe?
- Nachricht an den Spieler

Beispiel:
{
  "whoseturn": 1,
  "bigfield": [0,0,1
              ,2,1,2
              ,1,2,0]
  "fields": [0,0,1,    [0,0,1,    [1,1,1,
             2,1,2,     2,2,2,     1,0,0,    etc.
             1,2,0],    1,0,0],    2,0,0],
  "message": "Player 2 has lost Connection.",
  "error": 0
}

Use Gem: "sinatra/json"

=end
