require 'test_helper'

class ChartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
    @chart_type = chart_types(:score)
    @chart_type_2 = chart_types(:centi_time)
    @chart_group = ChartGroup.create(name: "Group 1", parent_group: nil, order_in_parent: 1, game: @game)
    @chart_group_2 = ChartGroup.create(name: "Group 2", parent_group: nil, order_in_parent: 2, game: @game)
    @chart = Chart.create(name: "Chart 1", chart_type: @chart_type, chart_group: @chart_group, order_in_group: 1)
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
