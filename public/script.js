// jslint Settings:
/*jslint  browser:  true, devel: true, white: true, vars: true */
/*global  $, jQuery, ruby, hex_md5 */

// Globale Variablen:
var infobox, bigField, bigCells, loading, init, title, namesSet, connectionTimeout,
    dismissTimeout, reportTimeout, movenr, turnSpan, notYet, body, rematchTimeout, 
    smallCells, smallCells1, smallCells2, smallCells3, smallCells4,
    smallCells5, smallCells6,smallCells7, smallCells8, smallCells9,
    interval = [3,3,2,2,2,2,3,3,3,4,4,4,5,5,5,6,6,7,8,9,10,12], gameover = false,
    currentInterval = 0, numberOfClasses = 4, currentClass = 3;
function completeAJAX(){"use strict";}

// Diese Funktion zeigt eine Nachricht an. Das zweite Argument ist die Zeit in Sekunden.
// Zweites Argument weglassen: 4 Sekunden, Zweites Argument 0: Dauerhaft anzeigen
function dismissMessage() {
  "use strict";
  infobox.fadeOut('fast');
}
function showMessage(message, seconds) {
  "use strict";
  clearTimeout(dismissTimeout);
  infobox.text(message);
  infobox.show();
  if (seconds > 0) {
    dismissTimeout = setTimeout(dismissMessage, 1000 * seconds);
  }
}

// Diese Funktionen zeigen und verstecken die Formulare
function showForm(form) {
  "use strict";
  form.parent().show();
}
function hideForm(form) {
  "use strict";
  form.parent().fadeOut('fast');
}

// Diese Funktion regelt das Resize-Event:
function resizeField() {
  "use strict";
  if (smallCells) {
    var windowWidth = $(window).width();
    var windowHeight = $(window).height();
    if (windowWidth < 600 || windowHeight < 760) {
      if (windowWidth * 1.4 > windowHeight) {
        bigField.css({
          width: windowHeight * 0.7 + 'px',
          height: windowHeight * 0.7 + 'px'
        });
      } else {
        bigField.css({
          width: windowWidth * 0.99,
          height: windowWidth * 0.99
        });
      }
    } else {
      bigField.css({
        width: 550,
        height: 550
      });
    }
  }
}

// Diese Funktion sagt dem Spieler Bescheid, wenn er seine Verbindung verloren hat
function connectionLost() {
  "use strict";
  if(!gameover){
    showMessage('You lost your connection, try to reload the page.',0);
  }
}
function opponentGone() {
  "use strict";
  if(!gameover){
    showMessage('Seems your opponent has lost his connection. Keep the URL to resume the game later.', 0);
  }
}
function yourTurn() {
  "use strict";
  var texty = title.text();
  if (texty.substr(0,10) !== 'Your turn!') {
    title.text('Your turn! | ' + texty);
    turnSpan.text('It is your turn.');
  }
  
}
function notYourTurn() {
  "use strict";
  var texty = title.text();
  if (texty.substr(0,10) === 'Your turn!') {
    title.text(texty.substring(13));
    turnSpan.text('Waiting for opponent...');
  }
}

function animateField(field_nr) {
  "use strict";
  var celly = smallCells[Math.floor(field_nr/9)].first().parent().find("[data-fieldnr="+field_nr+"]");
  celly.append('<div class="animator"></div>');
}

// Diese Funktion liefert die Zeitabstände für die Requests
function nextInterval() {
  "use strict";
  var result = 1000 * ( currentInterval < interval.length ? interval[currentInterval] : interval[interval.length-1] );
  currentInterval += 1;
  return result;
}
function resetInterval() {
  "use strict";
  currentInterval = 0;
}

// Diese Funktion verteilt die Klassen aus "template" auf die jQuery Ergebnisse in "cells"
function putThese(cells,template) {
  "use strict";
  var i;
  for (i = 0; i < 9; i += 1) {
    // Für die grossen Felder:
    if (template[i] === '1') {
      if ( !cells.eq(i).hasClass('player1') ) {
        if ( cells.eq(i).hasClass('player2') )
          { cells.eq(i).removeClass('player2'); }
        if ( cells.eq(i).hasClass('yellow') )
          { cells.eq(i).removeClass('yellow'); }
        cells.eq(i).addClass('player1');
      }
    } else if (template[i] === '2') {
      if ( !cells.eq(i).hasClass('player2') ) {
        if ( cells.eq(i).hasClass('player1') )
          { cells.eq(i).removeClass('player1'); }
        if ( cells.eq(i).hasClass('yellow') )
          { cells.eq(i).removeClass('yellow'); }
        cells.eq(i).addClass('player2');
      }
    } else if (template[i] === 'y') {
      if ( !cells.eq(i).hasClass('yellow') ) {
        if ( cells.eq(i).hasClass('player2') )
          { cells.eq(i).removeClass('player2'); }
        if ( cells.eq(i).hasClass('player1') )
          { cells.eq(i).removeClass('player1'); }
        cells.eq(i).addClass('yellow');
      }
    } else {
      if ( cells.eq(i).hasClass('player2') )
        { cells.eq(i).removeClass('player2'); }
      if ( cells.eq(i).hasClass('yellow') )
        { cells.eq(i).removeClass('yellow'); }
      if ( cells.eq(i).hasClass('player1') )
        { cells.eq(i).removeClass('player1'); }
    }
  }
}
// Diese Funktion verteilt die CSS-Klassen der Felder
function putClasses(big_t,small_t,interactive) {
  "use strict";
  var k;
  var split_t = small_t.split(",");
  putThese(bigCells,big_t);
  for(k = 0; k < 9; k += 1){
    putThese(smallCells[k],split_t[k]);
  }
  if (interactive){
    bigCells.find('.small_cell.yellow').addClass('interactive');
  }
  if (!init) {
    hideForm($('#loading_screen'));
    init = true;
  }
}

// Diese Funktion wird ausgeführt, wenn der Rematch-Button geklickt wurde
function doRematch(iClickedFirst) {
  "use strict";
  $('#win_title').fadeOut('fast', function() {
    $('#names_title').fadeOut('fast', function() {
      $('#uttt_title').text('Rematch!').fadeIn();
    });
  });
  if (!iClickedFirst) {
    turnSpan.html('Waiting for opponent...<br/>Your Opponent wants a rematch!');
    $('#rematch').fadeOut(function() {
      $('#whoseturn').fadeIn();
    });
  } else {
    $('#whoseturn').fadeIn();
  }
  namesSet = false;
  gameover = false;
  init = false;
  resetInterval();
  completeAJAX();
}

// Diese Funktion meldet, dass ein Rematch gespielt werden soll
function askRematch() {
  "use strict";
  $('#rematch').fadeOut();
  var url = '/ttt/dorematch';
  clearTimeout(rematchTimeout);
  $.ajax({
    type: "POST",
    url: url,
    data: { gameid: ruby.gameid },
    dataType: 'text', success: function(data) {
      data = JSON.parse(data);
      if (data.rematch === 'true') {
        doRematch(true);
      } else if (data.rematch === 'late') {
        doRematch(false);
      }
    }
  });
}

// Diese Funktion checkt, ob ein Rematch angefangen wurde
function checkRematch() {
  "use strict";
  var url = '/ttt/rematch/' + ruby.gameid;
  $.ajax({
    type: "GET", url: url,
    cache: false, // Gegen einen Bug in Chrome 28
    dataType: 'text', success: function(data){
      data = JSON.parse(data);
      if (data.rematch === 'true') {
        doRematch(false);
      } else {
        rematchTimeout = setTimeout(checkRematch, nextInterval());
      }
    }
  });
}

// Diese Funktion regelt alles, wenn einer gewonnen hat:
function checkWin(data) {
  "use strict";
  if(data && data !== 0) {
    $('#names_title').fadeOut(function(){
      if (data === 1) {
        $('#win_title').find('span').text($('#p1name').text() + ' wins the match!').attr("id","p1name").parent().fadeIn();
      } else if (data === 2) {
        $('#win_title').find('span').text($('#p2name').text() + ' wins the match!').attr("id","p2name").parent().fadeIn();
      } else if (data === 3) {
        $('#win_title').find('span').text('The match ended in a tie.').parent().fadeIn();
      }
      turnSpan.text($('#win_title').text());
    });
    $('.animator').remove();
    $('.yellow').removeClass('yellow');
    $('.interactive').removeClass('interactive');
    $('#whoseturn').fadeOut(function() {
      $('#rematch').fadeIn();
    });
    notYourTurn();
    gameover = true;
    resetInterval();
    clearTimeout(connectionTimeout);
    checkRematch();
  }
}

//Diese Funktion Zeigt die Namen der Spieler oben an:
function putNames(p1name, p2name) {
  "use strict";
  if (!namesSet && p1name && p2name) {
    title.text(p1name + ' vs ' + p2name + ' | Ultimate Tic Tac Toe');
    $('#p1name').text(p1name);
    $('#p2name').text(p2name);
    $('#uttt_title').delay(1000).fadeOut('slow',function() {
      $('#names_title').fadeIn('slow');
    });
    namesSet = true;
  }
}
// Diese AJAX-Funktion meldet dem System, dass man noch am Start ist
// Ausserdem erfährt man, ob der Gegner noch da ist
function reportAJAX() {
  "use strict";
  var url = '/ttt/ajax_report/' + ruby.gameid;
  if (gameover) { return; }
  $.ajax({
    type: "GET", url: url, cache: false, // Gegen einen Bug in Chrome 28
    dataType: 'text', success: function(data){
      data = JSON.parse(data);
      clearTimeout(connectionTimeout);
      connectionTimeout = setTimeout(connectionLost,15000);
      if(data.whoseturn === 1){
        yourTurn();
        if (data.status !== -1) {
          notYet = false;
          resetInterval();
          reportTimeout = setTimeout(reportAJAX, 10000);
        } else {
          notYet = true;
          reportTimeout = setTimeout(reportAJAX, nextInterval());
        }
        if (notYet) {
          showMessage('Your opponent has not yet opened the game. Send him/her the URL to this page.', 0);
        } else if (data.status > (interval[interval.length-1]+2)) {
          opponentGone();
        } else {
          dismissMessage();
        }
      }
    }
  });
}
// Diese AJAX-Funktion zeichnet das Spielfeld
function completeAJAX() {
  "use strict";
  var url = '/ttt/ajax_complete/' + ruby.gameid;
  if (gameover) { return; }
  $.ajax({
    type: "GET", url: url,
    cache: false, // Gegen einen Bug in Chrome 28
    data: { init: init },
    dataType: 'text', success: function(data){
      data = JSON.parse(data);
      clearTimeout(connectionTimeout);
      connectionTimeout = setTimeout(connectionLost,15000);
      if (data.whoseturn === 1){  // Du bist dran!
        yourTurn();
        movenr.text(data.movecount);
        putClasses(data.bigfields, data.fields, true);
        animateField(data.lastfield);
        putNames(data.p1name,data.p2name);
        if (data.status !== -1) {  // ...nur wenn das Spiel schon begonnen hat.
          resetInterval();
          setTimeout(reportAJAX, 10000);
          notYet = false;
        } else {
          notYet = true;
          setTimeout(reportAJAX, nextInterval());
        }
      } else { // Du bist nicht dran!
        notYourTurn();
        if (data.status === -1) { notYet = true; } else { notYet = false; }
        if (!init) {
          movenr.text(data.movecount);
          putClasses(data.bigfields, data.fields);
          putNames(data.p1name,data.p2name);
        }
        setTimeout(completeAJAX, nextInterval());
      }
      checkWin(data.winner);
      if (notYet) {
        showMessage('Your opponent has not yet opened the game. Send him/her the URL to this page.', 0);
      } else if (data.status > 11) {
        opponentGone();
      } else {
        dismissMessage();
      }
    }
  });
}
// Diese AJAX-Funktion führt einen Zug aus!
function makeMove(field) {
  "use strict";
  var url = '/ttt/ajax_move';
  $.ajax({
    type: "POST",
    url: url,
    data: { field: field, gameid: ruby.gameid },
    dataType: 'text', success: function(data) {
      data = JSON.parse(data);
      clearTimeout(connectionTimeout);
      connectionTimeout = setTimeout(connectionLost,15000);
      clearTimeout(reportTimeout);
      bigCells.find('.small_cell.yellow').removeClass('interactive');
      movenr.text(data.movecount);
      putClasses(data.bigfields, data.fields);
      resetInterval();
      setTimeout(completeAJAX, nextInterval());
      notYourTurn();
      checkWin(data.winner);
      if (data.status === -1) {notYet = true; } else { notYet = false; }
      if (notYet) {
        showMessage('Your opponent has not yet opened the game. Send him/her the URL to this page.', 0);
      } else if (data.status > (interval[interval.length-1]+2)) {
        opponentGone();
      } else {
        dismissMessage();
      }
      loading.removeClass('loading');
    }
  });
}
// Diese Funktion blendet das Passwort-Feld ein.
function useapassword() {
  "use strict";
  $('#pwhint').fadeOut('fast', function() {
    $('#pwfield').fadeIn('fast');
  });
}
// Diese Funktion ändert die farben:
function togglecolors() {
  "use strict";
  currentClass = (currentClass + 1) % (numberOfClasses);
  body.removeClass();
  switch (currentClass) {
    case 0:
      body.addClass('eighties');
      break;
    case 1:
      body.addClass('dark');
      break;
    case 2:
      body.addClass('plus');
      break;
    default:
  }
}
// Diese Funktion wird nach dem Laden aufgerufen:
function uttt_initiate() {
  "use strict";
  // Merke:
  init = false;
  notYet = true;
  namesSet = false;
  infobox = $('#info_box');
  bigField = $('#big_field');
  movenr = $('#move_nr');
  turnSpan = $('#whoseturn');
  bigCells = bigField.find('.big_cell');
  title = $('title');
  body = $('body');
  smallCells1 = bigCells.filter('.top.left').find('.small_cell');
  smallCells2 = bigCells.filter('.top.center').find('.small_cell');
  smallCells3 = bigCells.filter('.top.right').find('.small_cell');
  smallCells4 = bigCells.filter('.middle.left').find('.small_cell');
  smallCells5 = bigCells.filter('.middle.center').find('.small_cell');
  smallCells6 = bigCells.filter('.middle.right').find('.small_cell');
  smallCells7 = bigCells.filter('.bottom.left').find('.small_cell');
  smallCells8 = bigCells.filter('.bottom.center').find('.small_cell');
  smallCells9 = bigCells.filter('.bottom.right').find('.small_cell');
  smallCells = [smallCells1, smallCells2, smallCells3, smallCells4,
                smallCells5, smallCells6,smallCells7, smallCells8, smallCells9];
  smallCells1.first().removeClass('loading');
  // Dynamische Texte einfügen:
  $('#player1span').text(ruby.p1name);
  $('#player2span').text(ruby.p2name);
  $('#player1radio').attr('value',ruby.p1name);
  $('#player2radio').attr('value',ruby.p2name);
  
  // Soll ein Formular angezeigt werden? Wenn ja, welches?
  if(ruby.forms === 1) {
    showForm($('#first_contact'));
    hideForm($('#loading_screen'));
  }
  if(ruby.forms === 2) {
    showForm($('#player_select'));
    hideForm($('#loading_screen'));
  }
  if(ruby.forms === 0) {
    completeAJAX();
  }
  
  resizeField();
}

// Document ready:
jQuery(function() {
  "use strict";
  uttt_initiate();
  
  // == Event-Handler registrieren == START
  // First-Contact Form Handler:
  $('#first_contact').submit(function(e) {
    e.preventDefault();
    var pw = $('#first_contact input[name="hash"]');
    var cpw = $('#first_contact input[name="custompw"]');
    var name_field = $('#first_contact input[name="name"]');
    
    // Ist das Name-Feld ausgefüllt?
    if(name_field.val().length === 0){
      alert('Please type in a name.'); // Fehler
      return;
    }
    // Wurde ein passwort gesetzt?
    if(pw.val().length === 0 ){  // Kein Passwort
      cpw.attr('value','0');
      var ran_hash = hex_md5(Math.random() + String); // +'' Fancy String conversion
      pw.val(ran_hash);
    } else {  // Es wurde ein Passwort gesetzt.
      cpw.attr('value','1');
      pw.val(hex_md5(pw.val()));
    }
    
    var data = {
      hash: pw.val(),
      name: name_field.val(),
      gameid: ruby.gameid,
      custompw: cpw.attr('value')
    };
    $.ajax({
      type: "POST",
      url: "/ttt/setname",
      data: JSON.stringify(data),
      dataType: 'text',
      success: function(data){
        if(data === "true"){
          hideForm($('#first_contact'));
          completeAJAX();
        }
      }
    });
    
  });
  
  // Player-Select Form Handler:
  $('#player_select').submit(function(e) {
    e.preventDefault();
    var pw = $('#input_password');
    var p1r = $('#player1radio');
    var p2r = $('#player2radio');
    
    // Ist einer der Spieler-Namen ausgewählt?
    if( !( p1r.is(':checked') || p2r.is(':checked') ) ){
      console.log('kein spieler ausgewählt'); // Fehler
      return;
    }
    // Ist das Passwort-Feld ausgefüllt, wenn nötig?
    if( pw.val().length === 0 &&
        ( ruby.passwords === 3 || 
        ( p1r.is(':checked') && ruby.passwords === 1 ) ||
        ( p2r.is(':checked') && ruby.passwords === 2 ) ) )
    {
      console.log('Fehlendes Passwort'); // Fehler
      return;
    }
    
    // Hash generieren
    if(pw.val().length > 0){
      pw.val(hex_md5(pw.val()));
    }
    
    var data = {
      hash: pw.val(),
      name: $('#player_select input[type="radio"]:checked').val(),
      gameid: ruby.gameid
    };
    $.ajax({
      type: "POST",
      url: "/ttt/playerselect",
      data: JSON.stringify(data),
      dataType: 'text',
      success: function(data){
        if(data === "true"){
          hideForm($('#player_select'));
          completeAJAX();
        } else {
          pw.val('');
          alert("Falsches Passwort");
        }
      }
    });
  });
  
  // Radio Button Handler:
  $('#player1radio').add('#player2radio').on('change', function() {
    $('#input_password').val('');
    if( ( $(this).val() === ruby.p1name && ruby.passwords === 1 ) ||
        ( $(this).val() === ruby.p2name && ruby.passwords === 2 ) ||
        ( ruby.passwords === 3 ))
    {
      $('#ask_password').show();
    } else {
      $('#ask_password').hide();
    }
  });
  
  bigField.on('click', '.small_cell', function() {
    var me = $(this);
    if (me.hasClass('interactive')){
      if (gameover) { return; }
      me.addClass('loading');
      loading = me;
      makeMove(me.attr('data-fieldnr'));
    } else {
      showMessage('Invalid move.', 3);
    }
  });
  // == Event-Handler registrieren == ENDE
  
});

$(window).resize(resizeField);