require 'test_helper'

class ChartTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:one)
    @game_2 = games(:two)
  end

  test "should get index" do
    get chart_types_url, as: :json
    assert_response :success
  end

  test "should get chart types of a game" do
    ct1 = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game)
    ct2 = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game)
    other_ct = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game_2)

    get chart_types_url(game_id: @game.id), as: :json
    assert_response :success
    chart_types = JSON.parse(response.body)['data']

    # Should contain ct1 and ct2, but not other_ct
    ct_ids = chart_types.map{|ct| ct['id']}
    assert_includes(ct_ids, ct1.id.to_s)
    assert_includes(ct_ids, ct2.id.to_s)
    assert_not_includes(ct_ids, other_ct.id.to_s)
  end

  test "should get chart types of a filter group" do
    ct1 = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game)
    ct2 = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game)
    other_ct = ChartType.create(
      name: "A name", format_spec: [{}], order_ascending: false, game: @game)

    # Link fg to ct1 and ct2, but not other_ct
    fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')
    ChartTypeFilterGroup.create(
      chart_type: ct1, filter_group: fg,
      order_in_chart_type: 1, show_by_default: false)
    ChartTypeFilterGroup.create(
      chart_type: ct2, filter_group: fg,
      order_in_chart_type: 1, show_by_default: false)
    # Link other_fg to other_ct
    other_fg = FilterGroup.create(
      name: "A name", description: "A description", kind: 'select')
    ChartTypeFilterGroup.create(
      chart_type: other_ct, filter_group: other_fg,
      order_in_chart_type: 1, show_by_default: false)

    get chart_types_url(filter_group_id: fg.id), as: :json
    assert_response :success
    chart_types = JSON.parse(response.body)['data']

    # Should contain ct1 and ct2, but not other_ct
    ct_ids = chart_types.map{|ct| ct['id']}
    assert_includes(ct_ids, ct1.id.to_s)
    assert_includes(ct_ids, ct2.id.to_s)
    assert_not_includes(ct_ids, other_ct.id.to_s)
  end

  test "should create chart type" do
    assert_difference('ChartType.count') do
      post chart_types_url, params: {
        data: {
          attributes: {
            name: "Score",
            'format-spec': '[{}]',
            'order-ascending': false,
          },
          relationships: {
            'game': { data: { type: 'games', id: @game.id } }
          },
          type: 'chart-types',
        }
      }, as: :json
    end
    assert_response :created

    # Check field values
    ct = ChartType.find(JSON.parse(response.body)['data']['id'])
    assert_equal("Score", ct.name)
    assert_equal('[{}]', ct.format_spec)
    assert_equal(false, ct.order_ascending)
    assert_equal(@game.id, ct.game.id)
  end

  test "should show chart type" do
    ct = ChartType.create(
      name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)

    get chart_type_url(ct), as: :json
    assert_response :success

    # Check field values
    ct = JSON.parse(response.body)['data']
    assert_equal("Score", ct['attributes']['name'])
    assert_equal('[{}]', ct['attributes']['format-spec'])
    assert_equal(false, ct['attributes']['order-ascending'])
    assert_equal(@game.id.to_s, ct['relationships']['game']['data']['id'])
  end

  test "should update chart type" do
    ct = ChartType.create(
      name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)

    patch chart_type_url(ct), params: {
      data: {
        attributes: {
          name: "Meters",
          'format-spec': '[{"suffix": "m"}]',
          'order-ascending': true,
        },
        relationships: {
          'game': { data: { type: 'games', id: @game_2.id } }
        },
        type: 'chart-types',
      }
    }, as: :json
    assert_response :success

    # Check field values
    ct.reload
    assert_equal("Meters", ct.name)
    assert_equal('[{"suffix": "m"}]', ct.format_spec)
    assert_equal(true, ct.order_ascending)
    assert_equal(@game_2.id, ct.game.id)
  end

  test "should destroy chart type" do
    ct = ChartType.create(
      name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)

    assert_difference('ChartType.count', -1) do
      delete chart_type_url(ct), as: :json
    end

    assert_response :no_content
  end
end
