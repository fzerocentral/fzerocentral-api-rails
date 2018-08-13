require 'test_helper'

class ChartTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = Game.new(name: "Game 1")
    @game.save
    @game_2 = Game.new(name: "Game 2")
    @game_2.save
    @chart_type = ChartType.new(name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)
    @chart_type.save
  end

  test "should get index" do
    get chart_types_url, as: :json
    assert_response :success
  end

  test "should create chart_type" do
    assert_difference('ChartType.count') do
      post chart_types_url, params: { chart_type: {
        name: "Meters",
        format_spec: '[{"suffix": "m"}]',
        order_ascending: false,
        game_id: @game.id,
      } }, as: :json
    end

    assert_response 201
  end

  test "should show chart_type" do
    get chart_type_url(@chart_type), as: :json
    assert_response :success
  end

  test "should update chart_type" do
    patch chart_type_url(@chart_type), params: { chart_type: {
        name: "Time",
        format_spec: '[{"multiplier": 60, "suffix": ":"}, {"digits": 2}]',
        order_ascending: true,
        game_id: @game_2.id,
      } }, as: :json
    assert_response 200
  end

  test "should destroy chart_type" do
    assert_difference('ChartType.count', -1) do
      delete chart_type_url(@chart_type), as: :json
    end

    assert_response 204
  end
end
