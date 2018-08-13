require 'test_helper'

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.new(username: "User 1")
    @user.save
    @user_2 = User.new(username: "User 2")
    @user_2.save
    @game = Game.new(name: "Game 1")
    @game.save
    @chart_type = ChartType.new(name: "Score", format_spec: '[{}]', order_ascending: false, game: @game)
    @chart_type.save
    @chart_group = ChartGroup.new(name: "Group 1", parent_group: nil, order_in_parent: 1, game: @game)
    @chart_group.save
    @chart = Chart.new(name: "Chart 1", chart_type: @chart_type, chart_group: @chart_group, order_in_group: 1)
    @chart.save
    @chart_2 = Chart.new(name: "Chart 2", chart_type: @chart_type, chart_group: @chart_group, order_in_group: 2)
    @chart_2.save
    @record = Record.new(value: 1234, chart: @chart, user: @user)
    @record.save
  end

  test "should get index" do
    get records_url, as: :json
    assert_response :success
  end

  test "should create record" do
    assert_difference('Record.count') do
      post records_url, params: { record: {
        value: 1408,
        chart_id: @chart.id,
        user_id: @user.id,
      } }, as: :json
    end

    assert_response 201
  end

  test "should show record" do
    get record_url(@record), as: :json
    assert_response :success
  end

  test "should update record" do
    patch record_url(@record), params: { record: {
        value: 1408,
        chart_id: @chart_2.id,
        user_id: @user_2.id,
      } }, as: :json
    assert_response 200
  end

  test "should destroy record" do
    assert_difference('Record.count', -1) do
      delete record_url(@record), as: :json
    end

    assert_response 204
  end
end
