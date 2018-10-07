require 'test_helper'

class ChartGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
    @chart_group = ChartGroup.create(name: "Group 1", parent_group: nil, order_in_parent: 1, game: @game)
    @chart_group_2 = ChartGroup.create(name: "Group 2", parent_group: nil, order_in_parent: 2, game: @game)
  end

  test "should get index" do
    get chart_groups_url, as: :json
    assert_response :success
  end

  test "should create chart_group" do
    assert_difference('ChartGroup.count') do
      post chart_groups_url, params: { chart_group: {
        name: "New Group",
        parent_group_id: @chart_group.id,
        order_in_parent: 1,
        game_id: @game.id,
      } }, as: :json
    end

    assert_response 201
  end

  test "should show chart_group" do
    get chart_group_url(@chart_group), as: :json
    assert_response :success
  end

  test "should update chart_group" do
    patch chart_group_url(@chart_group), params: { chart_group: {
      name: "Updated Group",
      parent_group_id: @chart_group_2.id,
      order_in_parent: 2,
      game_id: games(:two).id,
    } }, as: :json
    assert_response 200
  end

  test "should destroy chart_group" do
    assert_difference('ChartGroup.count', -1) do
      delete chart_group_url(@chart_group), as: :json
    end

    assert_response 204
  end
end
