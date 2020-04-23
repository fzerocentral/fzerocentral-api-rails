require 'test_helper'
require_relative './helpers'


class OrderTest < ActionDispatch::IntegrationTest
  setup do
    @game_1 = games(:one)
    @game_2 = games(:two)
    @cg_1 = ChartGroup.create(
      name: 'Group 1', parent_group: nil, order_in_parent: 1, game: @game_1)
    @cg_2 = ChartGroup.create(
      name: 'Group 2', parent_group: nil, order_in_parent: 2, game: @game_2)

    @ladder_1 = orm_create_ladder(game: @game_1, chart_group: @cg_1, order: 1)
    @ladder_2 = orm_create_ladder(game: @game_1, chart_group: @cg_1, order: 2)
    @ladder_3 = orm_create_ladder(game: @game_1, chart_group: @cg_1, order: 3)
    @ladder_4 = orm_create_ladder(game: @game_1, chart_group: @cg_1, order: 4)
    @ladder_5 = orm_create_ladder(game: @game_1, chart_group: @cg_1, order: 5)
  end

  def check_ladder_order(ordered_ladders)
    # Assert that the ordered_ladders are in consecutive order starting from 1.
    ordered_ladders.each_with_index do |ladder, index|
      ladder.reload
      assert_equal(index + 1, ladder.order_in_game_and_kind)
    end
  end

  test "should update ladder: order not given" do
    update_ladder(ladder_url(@ladder_3), {chart_group: @cg_2})
    assert_response :success

    # Update should have gone through
    @ladder_3.reload
    assert_equal(@cg_2.id, @ladder_3.chart_group_id)
    # Order should be same as before
    check_ladder_order([@ladder_1, @ladder_2, @ladder_3, @ladder_4, @ladder_5])
  end

  test "should update ladder: order same as before" do
    update_ladder(ladder_url(@ladder_3), {chart_group: @cg_2, order: 3})
    assert_response :success

    # Update should have gone through
    @ladder_3.reload
    assert_equal(@cg_2.id, @ladder_3.chart_group_id)
    # Order should be same as before
    check_ladder_order([@ladder_1, @ladder_2, @ladder_3, @ladder_4, @ladder_5])
  end

  test "should update ladders: order 1" do
    update_ladder(ladder_url(@ladder_3), {order: 1})
    assert_response :success

    # Order should be updated accordingly
    check_ladder_order([@ladder_3, @ladder_1, @ladder_2, @ladder_4, @ladder_5])
  end

  test "should update ladders: current < order < n" do
    update_ladder(ladder_url(@ladder_3), {order: 4})
    assert_response :success

    # Order should be updated accordingly
    check_ladder_order([@ladder_1, @ladder_2, @ladder_4, @ladder_3, @ladder_5])
  end

  test "should update ladders: order n" do
    update_ladder(ladder_url(@ladder_3), {order: 5})
    assert_response :success

    # Order should be updated accordingly
    check_ladder_order([@ladder_1, @ladder_2, @ladder_4, @ladder_5, @ladder_3])
  end

  test "should update ladders: order < 1" do
    update_ladder(ladder_url(@ladder_3), {order: -2})
    assert_response :success

    # Order should be updated accordingly (< 1 gets snapped to 1)
    check_ladder_order([@ladder_3, @ladder_1, @ladder_2, @ladder_4, @ladder_5])
  end

  test "should update ladders: order > n" do
    update_ladder(ladder_url(@ladder_3), {order: 7})
    assert_response :success

    # Order should be updated accordingly (> n gets snapped to n)
    check_ladder_order([@ladder_1, @ladder_2, @ladder_4, @ladder_5, @ladder_3])
  end

  test "should destroy ladder: order 1" do
    assert_difference('Ladder.count', -1) do
      delete ladder_url(@ladder_1), as: :json
    end
    assert_response :no_content

    # Check order of remaining ladders
    check_ladder_order([@ladder_2, @ladder_3, @ladder_4, @ladder_5])
  end

  test "should destroy ladder: 1 < order < n" do
    assert_difference('Ladder.count', -1) do
      delete ladder_url(@ladder_3), as: :json
    end
    assert_response :no_content

    # Check order of remaining ladders
    check_ladder_order([@ladder_1, @ladder_2, @ladder_4, @ladder_5])
  end

  test "should destroy ladder: order n" do
    assert_difference('Ladder.count', -1) do
      delete ladder_url(@ladder_5), as: :json
    end
    assert_response :no_content

    # Check order of remaining ladders
    check_ladder_order([@ladder_1, @ladder_2, @ladder_3, @ladder_4])
  end
end
