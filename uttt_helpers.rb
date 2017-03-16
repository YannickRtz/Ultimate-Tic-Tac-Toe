helpers do
  def uttt_evaluate(f)
    result = "NNNNNNNNN"
    for i in 0..8
      for c in 0..2
        if f[i][0+c*3] == f[i][1+c*3] && f[i][1+c*3] == f[i][2+c*3] then # Zeilen
          if f[i][0+c*3] != 'y' && f[i][0+c*3] != 'N' then
            result[i] = f[i][0+c*3]
          end
        end
        if f[i][0+c] == f[i][3+c] && f[i][3+c] == f[i][6+c] then # Spalten
          if f[i][0+c] != 'y' && f[i][0+c] != 'N' then
            result[i] = f[i][0+c]
          end
        end
      end
      if ( f[i][0] == f[i][4] && f[i][4] == f[i][8] ) ||
         ( f[i][2] == f[i][4] && f[i][4] == f[i][6] ) then # Diagonalen
        if f[i][4] != 'y' && f[i][4] != 'N' then
         result[i] = f[i][4]
        end
      end
    end
    return result
  end
  
  def normalWins(b)
    result = 0
    for c in 0..2
      if b[0+c*3] == b[1+c*3] && b[1+c*3] == b[2+c*3] then # Zeilen
        if b[0+c*3] != 'y' && b[0+c*3] != 'N' then
          result = b[0+c*3]
        end
      end
      if b[0+c] == b[3+c] && b[3+c] == b[6+c] then # Spalten
        if b[0+c] != 'y' && b[0+c] != 'N' then
          result = b[0+c]
        end
      end
    end
    if ( b[0] == b[4] && b[4] == b[8] ) ||
       ( b[2] == b[4] && b[4] == b[6] ) then # Diagonalen
      if b[4] != 'y' && b[4] != 'N' then
       result = b[4]
      end
    end
    return result
  end
  
  def mostWins(b)
    result = 0
    player1 = b.count('1')
    player2 = b.count('2')
    if player1 > player2
      result = 1
    elsif player2 > player1
      result = 2
    else
      result = 3
    end
    return result
  end
end