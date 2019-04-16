require 'test_helper'

class FiltersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filter_group = filter_groups(:one)
    @filter = Filter.create(
      name: "Filter 1A", filter_group: @filter_group)
  end

  test "should get index" do
    get filters_url, as: :json
    assert_response :success
  end

  test "should create filter" do
    assert_difference('Filter.count') do
      post filters_url, params: {
        data: {
          relationships: {
            'filter-group': { data: {
              type: 'filter-groups', id: @filter.filter_group_id } },
          },
          attributes: {
            name: @filter.name,
            numeric_value: 50,
          },
          type: 'filters',
        },
      }, as: :json
    end

    assert_response 201
  end

  test "should show filter" do
    get filter_url(@filter), as: :json
    assert_response :success
  end

  test "should update filter" do
    patch filter_url(@filter), params: { filter: {
      filter_group_id: @filter.filter_group_id,
      name: @filter.name,
      numeric_value: 50,
    } }, as: :json
    assert_response 200
  end

  test "should destroy filter" do
    assert_difference('Filter.count', -1) do
      delete filter_url(@filter), as: :json
    end

    assert_response 204
  end
end
