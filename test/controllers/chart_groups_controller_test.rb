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
      post chart_groups_url, params: { chart_group: { parent_group_id: @chart_group.parent_group_id, order_in_parent: 3, game_id: @chart_group.game_id, name: @chart_group.name } }, as: :json
    end

    assert_response 201
  end

  test "should show chart_group" do
    get chart_group_url(@chart_group), as: :json
    assert_response :success
  end

  test "should update chart_group" do
    patch chart_group_url(@chart_group), params: { chart_group: { parent_group_id: @chart_group.parent_group_id, order_in_parent: @chart_group.order_in_parent, game_id: @chart_group.game_id, name: @chart_group.name } }, as: :json
    assert_response 200
  end

  test "should destroy chart_group" do
    assert_difference('ChartGroup.count', -1) do
      # To destroy a chart group, need to destroy its charts and child groups
      # first
      charts(:one).records.each do |record|
        delete record_url(record)
      end
      delete chart_url(charts(:one)), as: :json
      delete chart_group_url(@chart_group), as: :json
    end

    assert_response 204
  end
end
