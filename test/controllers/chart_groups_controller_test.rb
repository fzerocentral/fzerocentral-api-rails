require 'test_helper'

class ChartGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chart_group = chart_groups(:one)
  end

  test "should get index" do
    get chart_groups_url, as: :json
    assert_response :success
  end

  test "should create chart_group" do
    assert_difference('ChartGroup.count') do
      post chart_groups_url, params: { chart_group: { chart_group_id: @chart_group.chart_group_id, game_id: @chart_group.game_id, name: @chart_group.name } }, as: :json
    end

    assert_response 201
  end

  test "should show chart_group" do
    get chart_group_url(@chart_group), as: :json
    assert_response :success
  end

  test "should update chart_group" do
    patch chart_group_url(@chart_group), params: { chart_group: { chart_group_id: @chart_group.chart_group_id, game_id: @chart_group.game_id, name: @chart_group.name } }, as: :json
    assert_response 200
  end

  test "should destroy chart_group" do
    assert_difference('ChartGroup.count', -1) do
      delete chart_group_url(@chart_group), as: :json
    end

    assert_response 204
  end
end
