class TicTacToe
  def initialize
    @board = Array.new(3) { Array.new(3, " ") }
  end
  
  def print_board
    puts "-------------"
    @board.each do |row|
      puts row.map { |cell| " #{cell} |" }.join("\n") + "\n-------------"
    end
  end
  
  def make_move(player, row, col)
    if @board[row][col] == " "
      @board[row][col] = player
      return true
    else
      return false
    end
  end
  
  def check_win(player)
    win_patterns = [
      [[0,0], [0,1], [0,2]],
      [[1,0], [1,1], [1,2]],
      [[2,0], [2,1], [2,2]],
      [[0,0], [1,0], [2,0]],
      [[0,1], [1,1], [2,1]],
      [[0,2], [1,2], [2,2]],
      [[0,0], [1,1], [2,2]],
      [[0,2], [1,1], [2,0]]
    ]
    
    win_patterns.each do |pattern|
      if pattern.all? { |pos| @board[pos[0]][pos[1]] == player }
        return true
      end
    end
    
    return false
  end
  
  def game_loop
    current_player = "X"
    while true
      print_board
      puts "Player #{current_player}, make your move (row, col):"
      row, col = gets.chomp.split(",").map(&:to_i)
      if make_move(current_player, row, col)
        if check_win(current_player)
          print_board
          puts "Player #{current_player} wins!"
          break
        elsif @board.flatten.none? { |cell| cell == " " }
          print_board
          puts "It's a tie!"
          break
        else
          current_player = current_player == "X" ? "O" : "X"
        end
      else
        puts "Invalid move, please try again."
      end
    end
  end
end

game = TicTacToe.new
game.game_loop