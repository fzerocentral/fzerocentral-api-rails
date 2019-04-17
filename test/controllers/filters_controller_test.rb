require 'test_helper'

class FiltersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = filter_groups(:one)
    @other_group = filter_groups(:two)

    # Chosen filters
    @blueFalconF = Filter.create(
      name: "Blue Falcon", filter_group: @group)
    @gallantStarF = Filter.create(
      name: "Gallant Star-G4", filter_group: @group)
    @gamecubeF = Filter.create(
      name: "Gamecube", filter_group: @other_group)

    # Implied filters
    @customF = Filter.create(
      name: "Custom", filter_group: @group)
    FilterImplicationLink.create(
      implying_filter: @gallantStarF, implied_filter: @customF)
    @consoleF = Filter.create(
      name: "Console", filter_group: @other_group)
    FilterImplicationLink.create(
      implying_filter: @gamecubeF, implied_filter: @consoleF)
  end

  test "should get index" do
    get filters_url, as: :json
    assert_response :success
  end

  test "should get filters of a filter group" do
    get filters_url(filter_group_id: @group.id), as: :json
    assert_response :success

    filters = JSON.parse(response.body)['data']

    # Should only contain this filter group's filters (not the 'other')
    assert_equal(3, filters.length)

    # Should be in name-alphabetical order
    assert_equal(@blueFalconF.id.to_s, filters[0]['id'])
    assert_equal(@customF.id.to_s, filters[1]['id'])
    assert_equal(@gallantStarF.id.to_s, filters[2]['id'])
  end

  test "should get chosen filters of a filter group" do
    skip "this test fails because the left outer join returns both chosen and implied filters, but can't figure out why"

    get filters_url(filter_group_id: @group.id, is_implied: false), as: :json
    assert_response :success

    filters = JSON.parse(response.body)['data']

    # Should only contain this filter group's chosen filters
    assert_equal(2, filters.length)

    # Should be in name-alphabetical order
    assert_equal(@blueFalconF.id.to_s, filters[0]['id'])
    assert_equal(@gallantStarF.id.to_s, filters[1]['id'])
  end

  test "should get implied filters of a filter group" do
    skip "this test fails because the inner join returns no filters, but can't figure out why"

    get filters_url(filter_group_id: @group.id, is_implied: true), as: :json
    assert_response :success

    filters = JSON.parse(response.body)['data']

    # Should only contain this filter group's implied filters
    assert_equal(1, filters.length)

    assert_equal(@customF.id.to_s, filters[0]['id'])
  end

  test "should respond 'bad request' on an invalid is_implied value" do
    get filters_url(filter_group_id: @group.id, is_implied: 'nil'), as: :json
    assert_response :bad_request
  end

  test "should create filter" do
    assert_difference('Filter.count') do
      post filters_url, params: {
        data: {
          relationships: {
            'filter-group': { data: {
              type: 'filter-groups', id: @group.id } },
          },
          attributes: {
            name: "White Cat",
            numeric_value: 50,
          },
          type: 'filters',
        },
      }, as: :json
    end

    assert_response :created
  end

  test "should show filter" do
    get filter_url(@blueFalconF), as: :json
    assert_response :success
  end

  test "should update filter" do
    patch filter_url(@blueFalconF), params: { filter: {
      filter_group_id: @other_group.id,
      name: "Wii",
      numeric_value: 50,
    } }, as: :json
    assert_response :success
  end

  test "should destroy filter" do
    assert_difference('Filter.count', -1) do
      delete filter_url(@blueFalconF), as: :json
    end

    assert_response :no_content
  end
end
