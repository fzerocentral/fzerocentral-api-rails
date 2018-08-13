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
      post games_url, params: { game: { name: @game.name } }, as: :json
    end

    assert_response 201
  end

  test "should show game" do
    get game_url(@game), as: :json
    assert_response :success
  end

  test "should update game" do
    patch game_url(@game), params: { game: { name: @game.name } }, as: :json
    assert_response 200
  end

  test "should destroy game" do
    assert_difference('Game.count', -1) do
      # To destroy a game, need to destroy its chart groups first, and the
      # charts of those CGs
      delete record_url(records(:one)), as: :json
      delete chart_url(charts(:one)), as: :json
      delete chart_group_url(chart_groups(:one)), as: :json
      delete chart_type_url(chart_types(:one)), as: :json
      delete game_url(@game), as: :json
    end

    assert_response 204
  end
end
