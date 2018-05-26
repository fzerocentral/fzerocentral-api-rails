require 'test_helper'

class LeafChartGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @leaf_chart_group = leaf_chart_groups(:one)
  end

  test "should get index" do
    get leaf_chart_groups_url, as: :json
    assert_response :success
  end

  test "should create leaf_chart_group" do
    assert_difference('LeafChartGroup.count') do
      post leaf_chart_groups_url, params: { leaf_chart_group: { type: @leaf_chart_group.type } }, as: :json
    end

    assert_response 201
  end

  test "should show leaf_chart_group" do
    get leaf_chart_group_url(@leaf_chart_group), as: :json
    assert_response :success
  end

  test "should update leaf_chart_group" do
    patch leaf_chart_group_url(@leaf_chart_group), params: { leaf_chart_group: { type: @leaf_chart_group.type } }, as: :json
    assert_response 200
  end

  test "should destroy leaf_chart_group" do
    assert_difference('LeafChartGroup.count', -1) do
      delete leaf_chart_group_url(@leaf_chart_group), as: :json
    end

    assert_response 204
  end
end
