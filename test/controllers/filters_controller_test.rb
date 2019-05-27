require 'test_helper'


# Helper functions

def filter_params(
    fg: nil, name: nil, numeric_value: nil, usage_type: nil)
  attributes = {}
  if !name.nil?
    attributes['name'] = name
  end
  if !numeric_value.nil?
    attributes['numeric-value'] = numeric_value
  end
  if !usage_type.nil?
    attributes['usage-type'] = usage_type
  end

  relationships = {}
  if !fg.nil?
    relationships['filter-group'] = {
      data: { type: 'filter-groups', id: fg.id } }
  end

  return { data: {
    attributes: attributes,
    relationships: relationships,
    type: 'filters',
  } }
end

def create_link(implying_filter, implied_filter)
  post filter_implication_links_url, params: {
    data: {
      relationships: {
        'implying-filter': { data: {
          type: 'filters', id: implying_filter.id } },
        'implied-filter': { data: {
          type: 'filters', id: implied_filter.id } },
      },
      type: 'filter-implication-links',
    },
  }, as: :json
  new_link_data = JSON.parse(response.body)['data']
  if new_link_data
    return FilterImplicationLink.find(new_link_data['id'])
  else
    return nil
  end
end


class FiltersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = filter_groups(:one)
    @other_group = filter_groups(:two)
    @numeric_group = FilterGroup.create(
      name: "A name", description: "A description", kind: 'numeric')

    # Choosable filters
    @blueFalconF = Filter.create(
      name: "Blue Falcon", filter_group: @group, usage_type: 'choosable')
    @gallantStarF = Filter.create(
      name: "Gallant Star-G4", filter_group: @group, usage_type: 'choosable')
    @gamecubeF = Filter.create(
      name: "Gamecube", filter_group: @other_group, usage_type: 'choosable')

    # Implied filters
    @customF = Filter.create(
      name: "Custom", filter_group: @group, usage_type: 'implied')
    create_link(@gallantStarF, @customF)
    @consoleF = Filter.create(
      name: "Console", filter_group: @other_group, usage_type: 'implied')
    create_link(@gamecubeF, @consoleF)
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

  test "should get choosable filters of a filter group" do
    get filters_url(filter_group_id: @group.id, usage_type: 'choosable'), as: :json
    assert_response :success

    filters = JSON.parse(response.body)['data']

    # Should only contain this filter group's choosable filters
    assert_equal(2, filters.length)

    # Should be in name-alphabetical order
    assert_equal(@blueFalconF.id.to_s, filters[0]['id'])
    assert_equal(@gallantStarF.id.to_s, filters[1]['id'])
  end

  test "should get implied filters of a filter group" do
    get filters_url(filter_group_id: @group.id, usage_type: 'implied'), as: :json
    assert_response :success

    filters = JSON.parse(response.body)['data']

    # Should only contain this filter group's implied filters
    assert_equal(1, filters.length)

    assert_equal(@customF.id.to_s, filters[0]['id'])
  end

  test "should create filter" do
    params = filter_params(
      fg: @group, name: "White Cat", usage_type: 'choosable')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :created

    # Check field values
    filter = Filter.find(JSON.parse(response.body)['data']['id'])
    assert_equal("White Cat", filter.name)
    assert_equal('choosable', filter.usage_type)
  end

  test "filter creation with missing name should get error" do
    params = filter_params(
      fg: @group, usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/name', error['source']['pointer'])
    assert_equal("can't be blank", error['detail'])
  end

  test "filter creation with blank name should get error" do
    params = filter_params(
      fg: @group, name: '', usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/name', error['source']['pointer'])
    assert_equal("can't be blank", error['detail'])
  end

  test "filter creation with dupe name in same group should get error" do
    params = filter_params(
      fg: @group, name: 'Golden Fox', usage_type: 'choosable')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :success

    params = filter_params(
      fg: @group, name: 'Golden Fox', usage_type: 'implied')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/name', error['source']['pointer'])
    assert_equal(
      "'Golden Fox' is already taken by another filter in this group" \
      " (case insensitive)",
      error['detail'])
  end

  test "dupe name checking should be case insensitive" do
    params = filter_params(
      fg: @group, name: 'Golden Fox', usage_type: 'choosable')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :success

    params = filter_params(
      fg: @group, name: 'GOLDEN FOX', usage_type: 'implied')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/name', error['source']['pointer'])
    assert_equal(
      "'GOLDEN FOX' is already taken by another filter in this group" \
      " (case insensitive)",
      error['detail'])
  end

  test "filter creation with dupe name across groups should be OK" do
    params = filter_params(
      fg: @group, name: 'Golden Fox', usage_type: 'choosable')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :success

    params = filter_params(
      fg: @other_group, name: 'Golden Fox', usage_type: 'implied')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :success
  end

  test "should create numeric filter" do
    params = filter_params(
      fg: @numeric_group, name: "50%",
      numeric_value: 50, usage_type: 'choosable')
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :created

    # Check field values
    filter = Filter.find(JSON.parse(response.body)['data']['id'])
    assert_equal("50%", filter.name)
    assert_equal(50, filter.numeric_value)
    assert_equal('choosable', filter.usage_type)
  end

  test "numeric filter creation with missing numeric_value should get error" do
    params = filter_params(
      fg: @numeric_group, name: "50%", usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/numeric-value', error['source']['pointer'])
    assert_equal("can't be blank", error['detail'])
  end

  test "filter creation with non-numeric numeric_value should get error" do
    params = filter_params(
      fg: @numeric_group, name: "50%",
      numeric_value: '50a', usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/numeric-value', error['source']['pointer'])
    assert_equal("is not a number", error['detail'])
  end

  test "filter creation with non-integer numeric_value should get error" do
    params = filter_params(
      fg: @numeric_group, name: "50%",
      numeric_value: '50.0', usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/numeric-value', error['source']['pointer'])
    assert_equal("must be an integer", error['detail'])
  end

  test "filter creation with missing usage_type should end up with default" do
    params = filter_params(
      fg: @group, name: "White Cat")
    assert_difference('Filter.count') do
      post filters_url, params: params, as: :json
    end
    assert_response :created

    # Check field values
    filter = Filter.find(JSON.parse(response.body)['data']['id'])
    assert_equal('choosable', filter.usage_type)
  end

  test "filter creation with unsupported usage_type should get error" do
    params = filter_params(
      fg: @group, name: "White Cat", usage_type: 'type_b')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/usage-type', error['source']['pointer'])
    assert_equal(
      "should be either 'choosable' or 'implied', not 'type_b'",
      error['detail'])
  end

  test "filter creation with missing filter_group should get error" do
    params = filter_params(
      name: "White Cat", usage_type: 'choosable')
    assert_difference('Filter.count', 0) do
      post filters_url, params: params, as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/filter-group', error['source']['pointer'])
    assert_equal("must exist", error['detail'])
  end

  test "should show filter" do
    get filter_url(@blueFalconF), as: :json
    assert_response :success
  end

  test "should update filter" do
    params = filter_params(
      fg: @other_group, name: "Wii",
      numeric_value: 50, usage_type: 'choosable')
    patch filter_url(@blueFalconF), params: params, as: :json
    assert_response :success

    # Check field values
    filter = Filter.find(JSON.parse(response.body)['data']['id'])
    assert_equal("Wii", filter.name)
    assert_equal(50, filter.numeric_value)
    assert_equal('choosable', filter.usage_type)
  end

  test "should destroy filter" do
    assert_difference('Filter.count', -1) do
      delete filter_url(@blueFalconF), as: :json
    end
    assert_response :no_content
  end

  test "trying to destroy filter with incoming implications should get error" do
    assert_difference('Filter.count', 0) do
      delete filter_url(@customF), as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "Cannot delete filter; it has existing implications", error['detail'])
  end

  test "trying to destroy filter with outgoing implications should get error" do
    assert_difference('Filter.count', 0) do
      delete filter_url(@gallantStarF), as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "Cannot delete filter; it has existing implications", error['detail'])
  end

  test "trying to destroy filter used in records should get error" do
    game = games(:one)
    chart_type = chart_types(:score)
    chart_group = ChartGroup.create(name: "Group 1", parent_group: nil, order_in_parent: 1, game: game)
    chart = Chart.create(name: "Chart 1", chart_type: chart_type, chart_group: chart_group, order_in_group: 1)
    user = users(:one)
    record = Record.create(chart: chart, user: user, value: 10)
    RecordFilter.create(record: record, filter: @blueFalconF)

    assert_difference('Filter.count', 0) do
      delete filter_url(@blueFalconF), as: :json
    end
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "Cannot delete filter; it's used in one or more records", error['detail'])
  end
end
