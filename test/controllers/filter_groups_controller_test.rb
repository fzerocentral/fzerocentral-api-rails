require 'test_helper'

class FilterGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filter_group = filter_groups(:one)
  end

  test "should get index" do
    get filter_groups_url, as: :json
    assert_response :success
  end

  test "should create filter_group" do
    assert_difference('FilterGroup.count') do
      post filter_groups_url, params: { filter_group: {
        name: @filter_group.name,
        description: @filter_group.description,
        kind: @filter_group.kind,
      } }, as: :json
    end

    assert_response 201
  end

  test "should show filter_group" do
    get filter_group_url(@filter_group), as: :json
    assert_response :success
  end

  test "should update filter_group" do
    patch filter_group_url(@filter_group), params: { filter_group: {
      name: @filter_group.name,
      description: @filter_group.description,
      kind: @filter_group.kind,
    } }, as: :json
    assert_response 200
  end

  test "should destroy filter_group" do
    assert_difference('FilterGroup.count', -1) do
      delete filter_group_url(@filter_group), as: :json
    end

    assert_response 204
  end
end
