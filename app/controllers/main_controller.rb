class MainController < BaseController
  def index
    if game
      return redirect '/play' if game.game_over? == false
    end
    render
  end
end