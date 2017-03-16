# Controllers - Index

# Diese Route gibt das CSS aus
get '/uttt_style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :uttt_style, :views => 'views/uttt'
end


# Begruessung etc...
get '/ttt/?' do
  erb :index,
    :layout => :layout_uttt,
    :views => 'views/uttt'
end


# Generiert die neue GameID und leitet zur entsprechenden URL weiter
# Außerdem wird der Verursacher als Spieler eins markiert
get '/ttt/newgame' do
  # Neue Gameid generieren und überprüfen:
  while(true) do
    new_gameid = 9999999 + rand(90000000)
    break unless Games.exists?(id: new_gameid.to_s)
  end
  # Cookie als Markierung, dass er der erste Spieler für dieses Spiel sein muss
  response.set_cookie "uttt#{new_gameid}nr",
    { :value => '1', :expires => Time.now + 1209600 }
  redirect "/ttt/#{new_gameid}"
end


# Hier wird der Datenbankeintrag für das Spiel erstellt, wenn noch nicht vorhanden
# Außerdem werden Namen und Hashes, sowie first-time-Cookies gesetzt
# POST: Gameid, Name, Hash, has Custompw
post '/ttt/setname' do
  # Die JSON Daten in ein Objekt umwandeln:
  data = JSON.parse(request.body.read)
  
  unless Games.exists? data["gameid"]   # Es gibt noch keinen DB-Eintrag
    if request.cookies["uttt#{data["gameid"]}nr"] == '1' # Spieler eins trägt als erster seinen Namen ein
      game = Games.new(
        id: data["gameid"], p1name: data["name"], p1hash: data["hash"], p1haspw: data["custompw"],
        p1last: DateTime.now, winner: 0, whoseturn: 1, bigfield: 'NNNNNNNNN',
        fields: 'yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy')
      game.id = data["gameid"]
    else        # Spieler zwei trägt vor Spieler eins seinen Namen ein.
      response.set_cookie "uttt#{data["gameid"]}nr",
        { :value => '2', :expires => Time.now + 1209600 }
      game = Games.new(
        id: data["gameid"], p2name: data["name"], p2hash: data["hash"], p2haspw: data["custompw"],
        p2last: DateTime.now, winner: 0, whoseturn: 1, bigfield: 'NNNNNNNNN',
        fields: 'yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy')
      game.id = data["gameid"]
    end
  else                # Es gibt schon einen DB-Eintrag zu diesem Spiel
    game = Games.find data["gameid"]
    # Es gibt schon einen Cookie
    if request.cookies["uttt#{data["gameid"]}nr"] == '1' && game.p1last == nil
        game.p1name = data["name"]
        game.p1last = DateTime.now
        game.p1hash = data["hash"]
        game.p1haspw = data["custompw"]
    elsif game.p2last == nil        # Es gibt noch keinen Cookie
      response.set_cookie "uttt#{game.id}nr",
        { :value => '2', :expires => Time.now + 1209600 }
      game.p2name = data["name"]
      game.p2last = DateTime.now
      game.p2hash = data["hash"]
      game.p2haspw = data["custompw"]
    end
  end
  
  if game.save
    response.set_cookie "uttt#{game.id}name",
      { :value => data["name"], :expires => Time.now + 1209600 }
    response.set_cookie "uttt#{game.id}hash",
      { :value => data["hash"], :expires => Time.now + 1209600 }
    
    # Sende etwas zurück:
    return "true"
  else
    erb :newgame, :layout => :layout_uttt, :views => 'views/uttt'
  end
end


# Hier kommen bekannte Spieler in neuen Browsern an, sie werden geprüft (optionales PW)
# und bekommen die nötigen Cookies zum Spielen verpasst
# POST: Gameid, Name, Hash
post '/ttt/playerselect' do
  # Die JSON Daten in ein Objekt umwandeln:
  data = JSON.parse(request.body.read)
  
  if Games.exists? data["gameid"]
    game = Games.find data["gameid"]
    # Prüfen, welcher von beiden Spielern es ist:
    if data["name"] == game.p1name && (data["hash"] == game.p1hash || !game.p1haspw)
      response.set_cookie "uttt#{game.id}nr",
        { :value => '1', :expires => Time.now + 1209600 }
      response.set_cookie "uttt#{game.id}name",
        { :value => game.p1name, :expires => Time.now + 1209600 }
      response.set_cookie "uttt#{game.id}hash",
        { :value => game.p1hash, :expires => Time.now + 1209600 }
      return "true"
    elsif data["name"] == game.p2name && (data["hash"] == game.p2hash || !game.p2haspw)
      response.set_cookie "uttt#{game.id}nr",
        { :value => '2', :expires => Time.now + 1209600 }
      response.set_cookie "uttt#{game.id}name",
        { :value => game.p2name, :expires => Time.now + 1209600 }
      response.set_cookie "uttt#{game.id}hash",
        { :value => game.p2hash, :expires => Time.now + 1209600 }
      return "true"
    else
      "false"
      # Das muss an's Javascript gemeldet werden!
    end
  else
    "This Game does not seem to exits"
  end
end


# Diese Route gibt das komplette JSON-Array aus...
get '/ttt/ajax_complete/:gameid' do
  if Games.exists? params["gameid"]
    game = Games.find params["gameid"]
    playernr = request.cookies["uttt#{params[:gameid]}nr"].to_i
    playerhash = request.cookies["uttt#{params[:gameid]}hash"]
    # Passwort aus dem Cookie vergleichen:
    if ( ( playernr == 1 && playerhash == game.p1hash ) ||
         ( playernr == 2 && playerhash == game.p2hash ) )
      yourturn = (playernr == game.whoseturn ? 1 : 0)
      if game.p1last != nil && game.p2last != nil
        lastTimeOpponent = DateTime.now.to_i - (playernr == 1 ?
          game.p2last.to_datetime.to_i : game.p1last.to_datetime.to_i)
      else
        lastTimeOpponent = -1;
      end
      if playernr == 1 # Datenbank "Last Seen Time" aktualisieren
        game.p1last = DateTime.now
      else
        game.p2last = DateTime.now
      end
      unless game.save
        'Fehler beim Speichern der Uhrzeit' # Fehler
      end
      # Wenn der aktuelle Spieler jetzt an der Reihe ist => Spielfeld muss aktualisiert werden
      # Außerdem muss es aktualisiert werden, wenn es sich um die erste Anfrage handelt
      if yourturn == 1 || params["init"] == "false"
        bigfield = game.bigfield
        fields = game.fields
        movecount = fields.count "12"
        content_type :json
        { :whoseturn => yourturn, # Achtung, da der Client nicht weiß, welche Nr er hat: 1 = Du, 0 = nicht Du.
          :bigfields => bigfield, :fields => fields, :status => lastTimeOpponent,
          :movecount => movecount, :winner => game.winner, :p1name => game.p1name,
          :p2name => game.p2name, :lastfield => game.lastfield }.to_json
      else
        content_type :json
        { :whoseturn => yourturn, :status => lastTimeOpponent }.to_json
      end
    else # Falscher Hash!
      'Falscher Hash!' # Fehler
    end
  else # Spiel existiert nicht
    'Spiel existiert nicht!' # Fehler
  end
end


# Diese Route ruft der Spieler auf, der gerade an der Reihe ist, um zu sagen, dass er noch da ist
get '/ttt/ajax_report/:gameid' do
  if Games.exists? params["gameid"]
    game = Games.find params["gameid"]
    playernr = request.cookies["uttt#{params[:gameid]}nr"].to_i
    playerhash = request.cookies["uttt#{params[:gameid]}hash"]
    # Passwort aus dem Cookie vergleichen:
    if ( ( playernr == 1 && playerhash == game.p1hash ) ||
         ( playernr == 2 && playerhash == game.p2hash ) )
      yourturn = (playernr == game.whoseturn ? 1 : 0)
      # Ausrechnen, wann der Gegner zuletzt gesehen wurde
      if game.p1last != nil && game.p2last != nil
        lastTimeOpponent = DateTime.now.to_i - (playernr == 1 ?
          game.p2last.to_datetime.to_i : game.p1last.to_datetime.to_i)
      else
        lastTimeOpponent = -1; # Bedeutet, dass Gegner noch nicht angemeldet ist
      end
      # Datenbank "Last Seen Time" aktualisieren
      if playernr == 1
        game.p1last = DateTime.now
      else
        game.p2last = DateTime.now
      end
      unless game.save
        'Fehler beim Speichern der Uhrzeit' # Fehler
      end
      content_type :json
      { :whoseturn => yourturn, :status => lastTimeOpponent }.to_json
    else # Falscher Hash!
      'Falscher Hash!' # Fehler
    end
  else # Spiel existiert nicht
    'Spiel existiert nicht!' # Fehler
  end
end


# Diese Route validiert und führt durch: Einen Zug. Chooo chooo!
post '/ttt/ajax_move' do
  if Games.exists? params["gameid"]
    game = Games.find params["gameid"]
    playernr = request.cookies["uttt#{params[:gameid]}nr"].to_i
    playerhash = request.cookies["uttt#{params[:gameid]}hash"]
    # Passwort aus dem Cookie vergleichen:
    if ( ( playernr == 1 && playerhash == game.p1hash ) ||
         ( playernr == 2 && playerhash == game.p2hash ) )
      if game.whoseturn == playernr 
        fields_strings = game.fields.gsub(',','')
        field_nr = params["field"].to_i
        bigfield_nr = field_nr % 9
        if fields_strings[field_nr] == 'y'
          # Nachdem alles überprüft wurde, wird hier das gesetzte Feld eingetragen:
          fields_strings[field_nr] = playernr.to_s
          fields_strings.insert 9,  ','
          fields_strings.insert 19, ','
          fields_strings.insert 29, ','
          fields_strings.insert 39, ','
          fields_strings.insert 49, ','
          fields_strings.insert 59, ','
          fields_strings.insert 69, ','
          fields_strings.insert 79, ','
          # Bisherige y entfernen:
          fields_strings = fields_strings.gsub('y','N')
          fields_array = fields_strings.split ','
          # Farbe der großen Felder berechnen:
          game.bigfield = uttt_evaluate fields_array
          if ((game.bigfield[bigfield_nr] == 'N') && (fields_array[bigfield_nr].count('12') < 9))
            # Herkömmliche Zuordnung von 'y'
            fields_array[bigfield_nr].gsub!('N','y')
            fields_strings = fields_array.join(',')
          else
            # Der nächste Spieler darf frei platzieren
            for i in 0..9 do
              if game.bigfield[i] == 'N'
                # In diesem Feld geht noch etwas
                fields_array[i].gsub!('N','y')
              end
            end
            fields_strings = fields_array.join(',')
          end
          game.fields = fields_strings
          # Jetzt noch checken, ob jemand gewonnen hat:
          win = normalWins(game.bigfield)
          # win = 0 bedeutet, die Methode hat keinen Gewinner gefunden
          if win == 0 && game.fields.count('y') < 1
            # Es hat der gewonnen mit den meisten Feldern / Unentschieden
            win = mostWins(game.bigfield)
          end
          if win.to_i > 0
            game.winner = win.to_i
          end
        else
          'Ungueltiger Zug!' # Fehler
        end
        # Datenbank "Last Seen Time" aktualisieren
        if playernr == 1
          game.p1last = DateTime.now
        else
          game.p2last = DateTime.now
        end
        game.whoseturn = game.whoseturn == 1 ? 2 : 1
        game.lastfield = field_nr
        unless game.save
          'Fehler beim Speichern' # Fehler
        end
        # Movecount:
        movecount = game.fields.count "12"
        # Ausrechnen, wann der Gegner zuletzt gesehen wurde
        if game.p1last != nil && game.p2last != nil
          lastTimeOpponent = DateTime.now.to_i - (playernr == 1 ?
            game.p2last.to_datetime.to_i : game.p1last.to_datetime.to_i)
        else
          lastTimeOpponent = -1; # Bedeutet, dass Gegner noch nicht angemeldet ist
        end
        content_type :json
        { :whoseturn => 0, # Achtung, da der Client nicht weiß, welche Nr er hat: 1 = Du, 0 = nicht Du.
          :bigfields => game.bigfield, :fields => game.fields, :status => lastTimeOpponent,
          :movecount => movecount, :winner => game.winner, :lastfield => game.lastfield }.to_json
      else 
        'Falscher Spieler!' # Fehler
      end
    else # Falscher Hash!
      'Falscher Hash!' # Fehler
    end
  else # Spiel existiert nicht
    'Spiel existiert nicht!' # Fehler
  end
end


# Diese Route regelt eine Rematch-Anfrage
post '/ttt/dorematch' do
  if Games.exists? params["gameid"]
    game = Games.find params["gameid"]
    playernr = request.cookies["uttt#{params[:gameid]}nr"].to_i
    playerhash = request.cookies["uttt#{params[:gameid]}hash"]
    # Passwort aus dem Cookie vergleichen:
    if ( ( playernr == 1 && playerhash == game.p1hash ) ||
         ( playernr == 2 && playerhash == game.p2hash ) )
      if game.winner != 0 # Du hast als erster auf Rematch geklickt
        game.whoseturn = playernr
        game.bigfield = 'NNNNNNNNN'
        game.fields = 'yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy,yyyyyyyyy'
        response = 'true'
        game.winner = 0
        game.lastfield = nil
      else # Du hast als zweiter auf Rematch geklickt
        response = 'late'
      end
      # Datenbank "Last Seen Time" aktualisieren
      if playernr == 1
        game.p1last = DateTime.now
      else
        game.p2last = DateTime.now
      end
      unless game.save
        'Fehler beim Speichern' # Fehler
      end
      content_type :json
      { :rematch => response }.to_json
    else # Falscher Hash!
      'Falscher Hash!' # Fehler
    end
  else # Spiel existiert nicht
    'Spiel existiert nicht!' # Fehler
  end
end


# Diese Route sagt, ob ein Rematch angefragt wurde
get '/ttt/rematch/:gameid' do
  if Games.exists? params["gameid"]
    game = Games.find params["gameid"]
    playernr = request.cookies["uttt#{params[:gameid]}nr"].to_i
    playerhash = request.cookies["uttt#{params[:gameid]}hash"]
    # Passwort aus dem Cookie vergleichen:
    if ( ( playernr == 1 && playerhash == game.p1hash ) ||
         ( playernr == 2 && playerhash == game.p2hash ) )
      if game.winner != 0  # Kein Rematch
        response = 'false'
      else  # Ein Rematch!
        response = 'true'
      end
      # Datenbank "Last Seen Time" aktualisieren
      if playernr == 1
        game.p1last = DateTime.now
      else
        game.p2last = DateTime.now
      end
      unless game.save
        'Fehler beim Speichern der Uhrzeit' # Fehler
      end
      content_type :json
      { :rematch => response }.to_json
    else # Falscher Hash!
      'Falscher Hash!' # Fehler
    end
  else # Spiel existiert nicht
    'Spiel existiert nicht!' # Fehler
  end
end


# Diese Route löst das Löschen älterer DB-Einträge aus
get '/ttt/delete/?' do
  counter1 = 0
  counter2 = 0
  doit = false
  output = "Deleted the following: </br>"
  games = Games.all
  games.each do |game|
    doit = false
    p1name = " "
    p2name = " "
    if game.p1last != nil
      if game.p1last.to_i < ((DateTime.now).to_i - 1209600)
        doit = true
        p1name = game.p1name
      end
    end
    if game.p2last != nil
      if game.p2last.to_i < ((DateTime.now).to_i - 1209600)
        doit = true
        p2name = game.p2name
      end
    end
    if doit
      output += "Delete game #" + game.id + ": <b>" + p1name + " vs " + p2name + "</b></br>"
      counter2 += 1
      game.destroy
    else
      counter1 += 1
    end
  end
  output += 'Number of deleted games: ' + counter2.to_s + "</br>"
  output += 'Number of games still in DB: ' + counter1.to_s
  return output
end


# Diese Route zeigt dem Spieler das Spiel! Sie überprüft zunächst den Zustand des Spiels
get '/ttt/:gameid/?' do
  # Gameid noch einmal prüfen
  unless params[:gameid].to_s.size == 8 && params[:gameid].match(/^[0-9]*$/)
    redirect "/ttt"
  end
  message = ' '
  passwords = 0 # Diese Variable sagt, welche der beiden Spieler Passwörter verwenden: 0=0, 1=1, 2=2, 3=beide
  forms = 0  # Diese Variable sagt, ob keine, die erste oder die zweite Form angezeigt werden soll.
  @gameid = params[:gameid]
  @showurl = true
  # Überprüfe, ob der Spieler schon einen Cookie hat:
  if request.cookies.has_key?("uttt#{params[:gameid]}name")
    game = Games.find(params[:gameid])
    # Überprüfe ob es Spieler eins oder zwei ist
    if request.cookies["uttt#{params[:gameid]}name"] == game.p1name &&
      request.cookies["uttt#{params[:gameid]}hash"] == game.p1hash
        # if game.p2last == nil
        #   message += 'Auf anderen Spieler warten... '
        # else
        #   message += 'Es kann losgehen. '
        # end
        # message += 'KEIN FORMULAR, du bis Spieler 1. '
    elsif request.cookies["uttt#{params[:gameid]}name"] == game.p2name &&
      request.cookies["uttt#{params[:gameid]}hash"] == game.p2hash
        # if game.p1last == nil
        #   message += 'Auf anderen Spieler warten... '
        # else
        #   message += 'Es kann losgehen. '
        # end
        # message += 'KEIN FORMULAR, du bis Spieler 2. '
    else # Das darf nicht vorkommen
      message += 'Das darf nicht passieren'
    end
  else
    # Kein Cookie, hat der andere Spieler schon abgeschickt?
    unless Games.exists? params[:gameid]
      forms = 1  # Den ersten Dialog anzeigen.
      if request.cookies.has_key?("uttt#{params[:gameid]}nr")
        message += 'Du kannst Spieler 1 werden.'
      else
        @p1name = 'Someone'
        @showurl = false
        message += 'Du kannst Spieler 2 werden.'
      end
    else  # Der andere Spieler hat schon abgeschickt.
      game = Games.find(params[:gameid])
      if game.p1last != nil && game.p2last != nil
        if game.p1haspw then passwords += 1 end
        if game.p2haspw then passwords += 2 end
        forms = 2  # Den zweiten Dialog anzeigen.
        message += 'Das Spiel hat begonnen, welcher von beiden Spielern bist du?'
      elsif game.p1last == nil && request.cookies.has_key?("uttt#{params[:gameid]}nr")
        message += 'Du kannst Spieler 1 werden.'
        forms = 1  # Den ersten Dialog anzeigen.
      elsif game.p2last == nil && !request.cookies.has_key?("uttt#{params[:gameid]}nr")
        message += 'Du kannst Spieler 2 werden.'
        @showurl = false
        @p1name = game.p1name
        forms = 1  # Den ersten Dialog anzeigen.
      end
    end
  end
  
  # Hier wird ein JSON-Objekt erstellt, dass alle Infos enthält, die im JS benötigt werden.
  # @gameid ist  zusätzlich global sichtbar, um es in hidden form fields zu verwenden.
  message = { :message => message,
              :forms => forms,
              :gameid => @gameid,
              :passwords => passwords }
  if game != nil
    message.merge!( :p1name => game.p1name, :p2name => game.p2name )
  end
  @ruby = JSON message
  erb :game,
    :layout => :layout_uttt,
    :views => 'views/uttt'
end
