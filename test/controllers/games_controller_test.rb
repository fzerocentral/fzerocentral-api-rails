require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
  end

  test "should get index" do
    get games_url, as: :json
    assert_response :success
  end

  test "should create game" do
    assert_difference('Game.count') do
      post games_url, params: { game: { name: "New Game" } }, as: :json
    end

    assert_response 201
  end

  test "should show game" do
    get game_url(@game), as: :json
    assert_response :success
  end

  test "should update game" do
    patch game_url(@game), params: { game: { name: "Updated Game" } }, as: :json
    assert_response 200
  end

  test "should destroy game" do
    # For ease of deletion, create a game that's not attached to other objects
    game = Game.create(name: "New Game")
    # Then try to delete it
    assert_difference('Game.count', -1) do
      delete game_url(game), as: :json
    end

    assert_response 204
  end
end
