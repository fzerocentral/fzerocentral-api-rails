require 'test_helper'


# Helper functions

def create_ct(game: nil)
  return ChartType.create(
    name: "A name", format_spec: [{}], order_ascending: false, game: game)
end

def create_fg_for_ct(chart_type: nil, order: nil)
  fg = FilterGroup.create(
    name: "A name", description: "A description", kind: 'select')
  ChartTypeFilterGroup.create(
    chart_type: chart_type, filter_group: fg,
    order_in_chart_type: order, show_by_default: false)
  return fg
end


class FilterGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
    @chart_type = ChartType.create(
      name: "Score", format_spec: [{}], order_ascending: false, game: @game)
  end

  # Index tests

  test "should get index" do
    get filter_groups_url, as: :json
    assert_response :success
  end

  test "should get filter groups of a chart type in order" do
    fg1 = create_fg_for_ct(chart_type: @chart_type, order: 1)
    fg3 = create_fg_for_ct(chart_type: @chart_type, order: 3)
    fg2 = create_fg_for_ct(chart_type: @chart_type, order: 2)

    other_ct = create_ct(game: @game)
    other_fg = create_fg_for_ct(chart_type: other_ct, order: 1)

    get filter_groups_url(chart_type_id: @chart_type.id), as: :json
    assert_response :success

    filter_groups = JSON.parse(response.body)['data']

    # Should only contain this chart type's filter groups (not the 'other')
    assert_equal(3, filter_groups.length)

    # Should be in order based on order_in_chart_type field
    assert_equal(fg1.id.to_s, filter_groups[0]['id'])
    assert_equal(fg2.id.to_s, filter_groups[1]['id'])
    assert_equal(fg3.id.to_s, filter_groups[2]['id'])
  end

  test "should get filter groups for a chart in order" do
    # Same as getting by chart type, except a chart is specified, and the
    # controller should get the chart type from that chart
    fg1 = create_fg_for_ct(chart_type: @chart_type, order: 1)
    fg3 = create_fg_for_ct(chart_type: @chart_type, order: 3)
    fg2 = create_fg_for_ct(chart_type: @chart_type, order: 2)
    other_ct = create_ct(game: @game)
    other_fg = create_fg_for_ct(chart_type: other_ct, order: 1)

    chart_group = ChartGroup.create(
      name: "A CG", game: games(:one), order_in_parent: 1)
    chart = Chart.create(
      name: "A chart", chart_group: chart_group, order_in_group: 1,
      chart_type: @chart_type)

    get filter_groups_url(chart_id: chart.id), as: :json
    assert_response :success

    filter_groups = JSON.parse(response.body)['data']

    # Should only contain this chart type's filter groups (not the 'other')
    assert_equal(3, filter_groups.length)

    # Should be in order based on order_in_chart_type field
    assert_equal(fg1.id.to_s, filter_groups[0]['id'])
    assert_equal(fg2.id.to_s, filter_groups[1]['id'])
    assert_equal(fg3.id.to_s, filter_groups[2]['id'])
  end

  test "should get filter groups for a record in order" do
    # Same as getting by chart type, except a record is specified, and the
    # controller should get the chart type from the record's chart
    fg1 = create_fg_for_ct(chart_type: @chart_type, order: 1)
    fg3 = create_fg_for_ct(chart_type: @chart_type, order: 3)
    fg2 = create_fg_for_ct(chart_type: @chart_type, order: 2)
    other_ct = create_ct(game: @game)
    other_fg = create_fg_for_ct(chart_type: other_ct, order: 1)

    chart_group = ChartGroup.create(
      name: "A CG", game: games(:one), order_in_parent: 1)
    chart = Chart.create(
      name: "A chart", chart_group: chart_group, order_in_group: 1,
      chart_type: @chart_type)
    record = Record.create(
      user: users(:one), chart: chart, value: 10)

    get filter_groups_url(record_id: record.id), as: :json
    assert_response :success

    filter_groups = JSON.parse(response.body)['data']

    # Should only contain this chart type's filter groups (not the 'other')
    assert_equal(3, filter_groups.length)

    # Should be in order based on order_in_chart_type field
    assert_equal(fg1.id.to_s, filter_groups[0]['id'])
    assert_equal(fg2.id.to_s, filter_groups[1]['id'])
    assert_equal(fg3.id.to_s, filter_groups[2]['id'])
  end

  test "should get filter groups for a game" do
    # Chart types in this game
    fg1 = create_fg_for_ct(chart_type: @chart_type, order: 1)
    ct2 = create_ct(game: @game)
    fg2 = create_fg_for_ct(chart_type: ct2, order: 1)
    # Chart type in another game
    other_ct = create_ct(game: games(:two))
    other_fg = create_fg_for_ct(chart_type: other_ct, order: 1)

    get filter_groups_url(game_id: @game.id), as: :json
    assert_response :success
    filter_groups = JSON.parse(response.body)['data']

    # Should only contain this game's filter groups (not the 'other')
    assert_equal(2, filter_groups.length)
    # Agnostic to order
    fg_ids = filter_groups.map{|fg| fg['id']}
    assert_includes(fg_ids, fg1.id.to_s)
    assert_includes(fg_ids, fg2.id.to_s)
    assert_not_includes(fg_ids, other_fg.id.to_s)
  end

  test "should get orphaned filter groups (not belonging to a chart type)" do
    fg_with_ct = create_fg_for_ct(chart_type: @chart_type, order: 1)
    orphan_fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')

    # We ask for orphaned FGs by giving an empty-string chart type ID
    get filter_groups_url(chart_type_id: ''), as: :json
    assert_response :success
    filter_groups = JSON.parse(response.body)['data']

    # Should contain orphan_fg, but not fg_with_ct
    fg_ids = filter_groups.map{|fg| fg['id']}
    assert_includes(fg_ids, orphan_fg.id.to_s)
    assert_not_includes(fg_ids, fg_with_ct.id.to_s)
  end

  # Create, show, update, destroy tests

  test "should create filter group" do
    assert_difference('FilterGroup.count') do
      post filter_groups_url, params: {
        data: {
          attributes: {
            name: "A name",
            description: "A description",
            kind: 'numeric',
          },
          type: 'filter-groups',
        }
      }, as: :json
    end
    assert_response :created

    # Check field values
    fg = FilterGroup.find(JSON.parse(response.body)['data']['id'])
    assert_equal("A name", fg.name)
    assert_equal("A description", fg.description)
    assert_equal('numeric', fg.kind)
  end

  test "should show filter group" do
    fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')

    get filter_group_url(fg), as: :json
    assert_response :success

    # Check field values
    fg = JSON.parse(response.body)['data']
    assert_equal("A name", fg['attributes']['name'])
    assert_equal("A description", fg['attributes']['description'])
    assert_equal('select', fg['attributes']['kind'])
  end

  test "should update filter group" do
    fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')

    patch filter_group_url(fg), params: {
      data: {
        attributes: {
          name: "Name 2",
          description: "Description 2",
          kind: 'numeric',
        },
        type: 'filter-groups',
      }
    }, as: :json
    assert_response :success

    # Check field values
    fg.reload
    assert_equal("Name 2", fg.name)
    assert_equal("Description 2", fg.description)
    assert_equal('numeric', fg.kind)
  end

  test "should destroy filter group" do
    fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')

    assert_difference('FilterGroup.count', -1) do
      delete filter_group_url(fg), as: :json
    end

    assert_response :no_content
  end
end
