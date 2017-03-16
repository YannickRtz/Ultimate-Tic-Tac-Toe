# Controllers - Index


# Diese Route zeigt die Startseite an
get '/' do
  # @testvar = Games.first.player1name
  erb :index,
    :layout => :layout_index,
    :views => 'views/index'
end


# Diese Route gibt das CSS aus
get '/index_style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :index_style, :views => 'views/index'
end