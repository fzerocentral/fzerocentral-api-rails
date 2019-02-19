require 'test_helper'


# Helper functions

def ctfg_params(
    ct: nil, fg: nil, order: nil, show_by_default: nil)
  attributes = {}
  if !order.nil?
    attributes['order-in-chart-type'] = order
  end
  if !show_by_default.nil?
    attributes['show-by-default'] = show_by_default
  end

  relationships = {}
  if !ct.nil?
    relationships['chart-type'] = {
      data: { type: 'chart-types', id: ct.id } }
  end
  if !fg.nil?
    relationships['filter-group'] = {
      data: { type: 'filter-groups', id: fg.id } }
  end

  return { data: {
    attributes: attributes,
    relationships: relationships,
    type: 'chart-type-filter-groups',
  } }
end

def orm_create_ctfg(chart_type, filter_group, order, show_by_default: false)
  return ChartTypeFilterGroup.create(
    chart_type: chart_type, filter_group: filter_group,
    order_in_chart_type: order, show_by_default: show_by_default)
end


class ChartTypeFilterGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
    @ct1 = ChartType.create(
      name: "CT1", format_spec: [{}], order_ascending: false, game: @game)
    @ct2 = ChartType.create(
      name: "CT2", format_spec: [{}], order_ascending: false, game: @game)
    @ct3 = ChartType.create(
      name: "CT3", format_spec: [{}], order_ascending: false, game: @game)
    @fg1 = FilterGroup.create(
      name: "FG1", description: "A description", kind: 'select')
    @fg2 = FilterGroup.create(
      name: "FG2", description: "A description", kind: 'select')
    @fg3 = FilterGroup.create(
      name: "FG3", description: "A description", kind: 'select')
    @fg4 = FilterGroup.create(
      name: "FG4", description: "A description", kind: 'select')
    @fg5 = FilterGroup.create(
      name: "FG5", description: "A description", kind: 'select')
  end

  # Index tests

  test "should get index" do
    orm_create_ctfg(@ct1, @fg1, 1)

    get chart_type_filter_groups_url, as: :json
    assert_response :success
  end

  test "should get CT-FG links of a chart type in order" do
    ctfg_order2 = orm_create_ctfg(@ct1, @fg1, 2)
    ctfg_order1 = orm_create_ctfg(@ct1, @fg3, 1)
    ctfg_order3 = orm_create_ctfg(@ct1, @fg2, 3)
    orm_create_ctfg(@ct2, @fg4, 1)

    get chart_type_filter_groups_url(chart_type_id: @ct1.id), as: :json
    assert_response :success
    ctfgs = JSON.parse(response.body)['data']

    # Should only contain CT1's links, in order
    assert_equal(3, ctfgs.length)
    assert_equal(ctfg_order1.id.to_s, ctfgs[0]['id'])
    assert_equal(ctfg_order2.id.to_s, ctfgs[1]['id'])
    assert_equal(ctfg_order3.id.to_s, ctfgs[2]['id'])
  end

  test "should get CT-FG links of a filter group in order" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct2, @fg1, 1)
    other_ctfg = orm_create_ctfg(@ct1, @fg2, 2)

    get chart_type_filter_groups_url(filter_group_id: @fg1.id), as: :json
    assert_response :success
    ctfgs = JSON.parse(response.body)['data']

    # Should only contain FG1's links
    assert_equal(2, ctfgs.length)
    ctfg_ids = ctfgs.map{|ctfg| ctfg['id']}
    assert_includes(ctfg_ids, ctfg_1.id.to_s)
    assert_includes(ctfg_ids, ctfg_2.id.to_s)
    assert_not_includes(ctfg_ids, other_ctfg.id.to_s)
  end

  # Show tests

  test "should show CT-FG link" do
    ctfg = orm_create_ctfg(@ct1, @fg1, 1, show_by_default: false)

    get chart_type_filter_group_url(ctfg), as: :json
    assert_response :success

    # Check field values
    ctfg = JSON.parse(response.body)['data']
    assert_equal(1, ctfg['attributes']['order-in-chart-type'])
    assert_equal(false, ctfg['attributes']['show-by-default'])
    assert_equal(
      @ct1.id.to_s, ctfg['relationships']['chart-type']['data']['id'])
    assert_equal(
      @fg1.id.to_s, ctfg['relationships']['filter-group']['data']['id'])
  end

  # Create tests

  test "should create CT-FG link: CT has no FGs yet, order not given" do
    params = ctfg_params(ct: @ct1, fg: @fg1, show_by_default: true)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check field values; order should be 1
    ctfg = ChartTypeFilterGroup.find(JSON.parse(response.body)['data']['id'])
    assert_equal(@ct1.id, ctfg.chart_type.id)
    assert_equal(@fg1.id, ctfg.filter_group.id)
    assert_equal(1, ctfg.order_in_chart_type)
    assert_equal(true, ctfg.show_by_default)
  end

  test "should create CT-FG link: CT has FGs, order not given" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; should be 3 for the created CTFG
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, new_ctfg.order_in_chart_type)
  end

  test "should create CT-FG link: CT has no FGs yet, order 1" do
    params = ctfg_params(ct: @ct1, fg: @fg1, order: 1)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Created CTFG's order should be 1
    ctfg = ChartTypeFilterGroup.find(JSON.parse(response.body)['data']['id'])
    assert_equal(1, ctfg.order_in_chart_type)
  end

  test "should create CT-FG link: CT has FGs, order 1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3, order: 1)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; new CTFG should be inserted properly
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, new_ctfg.order_in_chart_type)
    assert_equal(2, ctfg_1.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
  end

  test "should create CT-FG link: CT has n FGs, 1 < order < n+1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3, order: 2)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; new CTFG should be inserted properly
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, new_ctfg.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
  end

  test "should create CT-FG link: CT has n FGs, order n+1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3, order: 3)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; new CTFG should be inserted properly
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, new_ctfg.order_in_chart_type)
  end

  test "should create CT-FG link: CT has FGs, order < 1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3, order: -1)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; new CTFG should have order 1
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, new_ctfg.order_in_chart_type)
    assert_equal(2, ctfg_1.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
  end

  test "should create CT-FG link: CT has n FGs, order > n+1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)

    params = ctfg_params(ct: @ct1, fg: @fg3, order: 5)
    post chart_type_filter_groups_url, params: params, as: :json
    assert_response :created

    # Check order; new CTFG should have order n+1
    ctfg_1.reload()
    ctfg_2.reload()
    new_ctfg = ChartTypeFilterGroup.find(
      JSON.parse(response.body)['data']['id'])
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, new_ctfg.order_in_chart_type)
  end

  # Update tests

  test "should not allow updating chart type or filter group" do
    ctfg = orm_create_ctfg(@ct1, @fg1, 1, show_by_default: true)

    params = ctfg_params(ct: @ct2, fg: @fg2, show_by_default: false)
    patch chart_type_filter_group_url(ctfg), params: params, as: :json
    assert_response :success

    # Check field values; show_by_default should update, but CT shouldn't
    ctfg.reload
    assert_equal(@ct1.id, ctfg.chart_type.id)
    assert_equal(@fg1.id, ctfg.filter_group.id)
    assert_equal(false, ctfg.show_by_default)
  end

  test "should update CT-FG link: order not given" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be same as before
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, ctfg_3.order_in_chart_type)
    assert_equal(4, ctfg_4.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG link: order same as before" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 3, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be same as before
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, ctfg_3.order_in_chart_type)
    assert_equal(4, ctfg_4.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: order 1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 1, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_3.order_in_chart_type)
    assert_equal(2, ctfg_1.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
    assert_equal(4, ctfg_4.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: 1 < order < current" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 2, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_3.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
    assert_equal(4, ctfg_4.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: current < order < n" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 4, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, ctfg_4.order_in_chart_type)
    assert_equal(4, ctfg_3.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: order n" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 5, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, ctfg_4.order_in_chart_type)
    assert_equal(4, ctfg_5.order_in_chart_type)
    assert_equal(5, ctfg_3.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: order < 1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: -1, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_3.order_in_chart_type)
    assert_equal(2, ctfg_1.order_in_chart_type)
    assert_equal(3, ctfg_2.order_in_chart_type)
    assert_equal(4, ctfg_4.order_in_chart_type)
    assert_equal(5, ctfg_5.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  test "should update CT-FG links: order > n" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3, show_by_default: true)
    ctfg_4 = orm_create_ctfg(@ct1, @fg4, 4)
    ctfg_5 = orm_create_ctfg(@ct1, @fg5, 5)

    params = ctfg_params(order: 7, show_by_default: false)
    patch chart_type_filter_group_url(ctfg_3), params: params, as: :json
    assert_response :success

    # Check field values; order should be updated accordingly
    ctfg_1.reload; ctfg_2.reload; ctfg_3.reload; ctfg_4.reload; ctfg_5.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
    assert_equal(3, ctfg_4.order_in_chart_type)
    assert_equal(4, ctfg_5.order_in_chart_type)
    assert_equal(5, ctfg_3.order_in_chart_type)
    assert_equal(false, ctfg_3.show_by_default)
  end

  # Destroy tests

  test "should destroy CT-FG link: no other FGs in this CT" do
    ctfg = orm_create_ctfg(@ct1, @fg1, 1)

    assert_difference('ChartTypeFilterGroup.count', -1) do
      delete chart_type_filter_group_url(ctfg), as: :json
    end
    assert_response :no_content
  end

  test "should destroy CT-FG link: order 1" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3)

    assert_difference('ChartTypeFilterGroup.count', -1) do
      delete chart_type_filter_group_url(ctfg_1), as: :json
    end
    assert_response :no_content

    # Check order of remaining CTFGs
    ctfg_2.reload; ctfg_3.reload
    assert_equal(1, ctfg_2.order_in_chart_type)
    assert_equal(2, ctfg_3.order_in_chart_type)
  end

  test "should destroy CT-FG link: 1 < order < n" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3)

    assert_difference('ChartTypeFilterGroup.count', -1) do
      delete chart_type_filter_group_url(ctfg_2), as: :json
    end
    assert_response :no_content

    # Check order of remaining CTFGs
    ctfg_1.reload; ctfg_3.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_3.order_in_chart_type)
  end

  test "should destroy CT-FG link: order n" do
    ctfg_1 = orm_create_ctfg(@ct1, @fg1, 1)
    ctfg_2 = orm_create_ctfg(@ct1, @fg2, 2)
    ctfg_3 = orm_create_ctfg(@ct1, @fg3, 3)

    assert_difference('ChartTypeFilterGroup.count', -1) do
      delete chart_type_filter_group_url(ctfg_3), as: :json
    end
    assert_response :no_content

    # Check order of remaining CTFGs
    ctfg_1.reload; ctfg_2.reload
    assert_equal(1, ctfg_1.order_in_chart_type)
    assert_equal(2, ctfg_2.order_in_chart_type)
  end
end
