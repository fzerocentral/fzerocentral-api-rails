require 'test_helper'
require_relative './helpers'


class GeneralTest < ActionDispatch::IntegrationTest
  setup do
    @game_1 = games(:one)
    @game_2 = games(:two)
    @cg_1 = ChartGroup.create(
      name: 'Group 1', parent_group: nil, order_in_parent: 1, game: @game_1)
    @cg_2 = ChartGroup.create(
      name: 'Group 2', parent_group: nil, order_in_parent: 2, game: @game_2)
  end

  # Show multiple

  test 'should get all ladders' do
    orm_create_ladder(
      kind: 'main', game: @game_1, order: 1, chart_group: @cg_1)
    orm_create_ladder(
      kind: 'side', game: @game_2, order: 2, chart_group: @cg_2)

    get ladders_url, as: :json
    assert_response :success

    ladders = JSON.parse(response.body)['data']
    assert_equal(2, ladders.length, 'Should include both ladders')
  end

  test "should get ladders of a particular game and kind" do
    ladder_g1_main_1 = orm_create_ladder(
      kind: 'main', game: @game_1, order: 1, chart_group: @cg_1)
    ladder_g1_main_2 = orm_create_ladder(
      kind: 'main', game: @game_1, order: 2, chart_group: @cg_1)

    # Different game
    orm_create_ladder(
      kind: 'main', game: @game_2, order: 1, chart_group: @cg_2)
    # Different kind
    orm_create_ladder(
      kind: 'side', game: @game_1, order: 1, chart_group: @cg_1)

    get ladders_url(game_id: @game_1.id, kind: 'main'), as: :json
    assert_response :success

    ladders = JSON.parse(response.body)['data']

    # Should only include ladders of this game/kind
    ladder_ids = ladders.map{|ladder| ladder['id']}
    assert_includes(ladder_ids, ladder_g1_main_1.id.to_s)
    assert_includes(ladder_ids, ladder_g1_main_2.id.to_s)
    assert_equal(2, ladders.length)
  end

  # Create

  test "should create ladder" do
    assert_difference('Ladder.count') do
      create_ladder(ladders_url, {
        name: 'New ladder', kind: 'main', filter_spec: '2,3n',
        chart_group: @cg_1, game: @game_1})
    end
    assert_response :created

    # Check field values. This test ignores the order field.
    ladder = get_created_ladder
    assert_equal('New ladder', ladder.name)
    assert_equal('main', ladder.kind)
    assert_equal('2,3n', ladder.filter_spec)
    assert_equal(@cg_1.id, ladder.chart_group_id)
    assert_equal(@game_1.id, ladder.game_id)
  end

  test "ladder creation with blank name should get error" do
    assert_difference('Ladder.count', 0) do
      create_ladder(ladders_url, {
        name: '', chart_group: @cg_1, game: @game_1})
    end
    assert_response :bad_request
    assert_field_error('/data/attributes/name', "can't be blank")
  end

  test "ladder creation with unrecognized kind should get error" do
    assert_difference('Ladder.count', 0) do
      create_ladder(ladders_url, {
        kind: 'unknown', chart_group: @cg_1, game: @game_1})
    end
    assert_response :bad_request
    assert_field_error(
      '/data/attributes/kind',
      "should be either 'main' or 'side', not 'unknown'")
  end

  test "ladder creation with empty string filter_spec should work" do
    assert_difference('Ladder.count') do
      create_ladder(ladders_url, {
        filter_spec: '', chart_group: @cg_1, game: @game_1})
    end
    assert_response :created

    ladder = get_created_ladder
    assert_equal('', ladder.filter_spec)
  end

  test "ladder creation should assign end order" do
    # First main ladder: order 1
    ladder = create_ladder(ladders_url, {
      kind: 'main', chart_group: @cg_1, game: @game_1})
    assert_equal(1, ladder.order_in_game_and_kind)

    # Second main ladder: order 2
    ladder = create_ladder(ladders_url, {
      kind: 'main', chart_group: @cg_1, game: @game_1})
    assert_equal(2, ladder.order_in_game_and_kind)

    # First side ladder: order 1
    ladder = create_ladder(ladders_url, {
      kind: 'side', chart_group: @cg_1, game: @game_1})
    assert_equal(1, ladder.order_in_game_and_kind)
  end

  # Show one

  test "should show ladder" do
    ladder = orm_create_ladder(
      chart_group: @cg_1, game: @game_1, order: 1)

    get ladder_url(ladder), as: :json
    assert_response :success
  end

  # Update

  test "should update fields other than game and kind" do
    ladder = orm_create_ladder(
      game: @game_1, kind: 'main', order: 1,
      name: 'Max Speed', filter_spec: '', chart_group: @cg_1)

    update_ladder(ladder_url(ladder), {
      game: @game_2, kind: 'side', order: 1,
      name: 'Snaking', filter_spec: '2,3n', chart_group: @cg_2})
    assert_response :success

    # Check field values. game and kind should be unchanged. We'll ignore
    # order for now.
    ladder = Ladder.find(ladder.id)
    assert_equal(@game_1.id, ladder.game_id)
    assert_equal('main', ladder.kind)
    assert_equal('Snaking', ladder.name)
    assert_equal('2,3n', ladder.filter_spec)
    assert_equal(@cg_2.id, ladder.chart_group_id)
  end

  # Delete

  test "should destroy ladder: no other ladders of same game and kind" do
    ladder = orm_create_ladder(
      game: @game_1, kind: 'main', order: 1, chart_group: @cg_1)

    assert_difference('Ladder.count', -1) do
      delete ladder_url(ladder), as: :json
    end

    assert_response :no_content
  end
end
