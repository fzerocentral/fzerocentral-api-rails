require 'test_helper'

class ChartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = Game.new(name: "Game 1")
    @game.save
    @chart_type = ChartType.new(name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)
    @chart_type.save
    @chart_type_2 = ChartType.new(name: "Meters", format_spec: '[{"suffix": "m"}]', order_ascending: false, game: @game)
    @chart_type_2.save
    @chart_group = ChartGroup.new(name: "Group 1", parent_group: nil, order_in_parent: 1, game: @game)
    @chart_group.save
    @chart_group_2 = ChartGroup.new(name: "Group 2", parent_group: nil, order_in_parent: 2, game: @game)
    @chart_group_2.save
    @chart = Chart.new(name: "Chart 1", chart_type: @chart_type, chart_group: @chart_group, order_in_group: 1)
    @chart.save
  end

  test "should get index" do
    get charts_url, as: :json
    assert_response :success
  end

  test "should create chart" do
    assert_difference('Chart.count') do
      post charts_url, params: { chart: {
        name: "Chart 2",
        chart_type_id: @chart_type.id,
        chart_group_id: @chart_group.id,
        order_in_group: 2,
      } }, as: :json
    end

    assert_response 201
  end

  test "should show chart" do
    get chart_url(@chart), as: :json
    assert_response :success
  end

  test "should update chart" do
    patch chart_url(@chart), params: { chart: {
        name: "Chart 2",
        chart_type_id: @chart_type_2.id,
        chart_group_id: @chart_group_2.id,
        order_in_group: 2,
      } }, as: :json
    assert_response 200
  end

  test "should destroy chart" do
    assert_difference('Chart.count', -1) do
      delete chart_url(@chart), as: :json
    end

    assert_response 204
  end
end
