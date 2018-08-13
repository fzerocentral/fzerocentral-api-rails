require 'test_helper'

class ChartTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chart_type = chart_types(:one)
  end

  test "should get index" do
    get chart_types_url, as: :json
    assert_response :success
  end

  test "should create chart_type" do
    assert_difference('ChartType.count') do
      post chart_types_url, params: { chart_type: { format_spec: @chart_type.format_spec, game_id: @chart_type.game_id, name: @chart_type.name, order_ascending: @chart_type.order_ascending } }, as: :json
    end

    assert_response 201
  end

  test "should show chart_type" do
    get chart_type_url(@chart_type), as: :json
    assert_response :success
  end

  test "should update chart_type" do
    patch chart_type_url(@chart_type), params: { chart_type: { format_spec: @chart_type.format_spec, game_id: @chart_type.game_id, name: @chart_type.name, order_ascending: @chart_type.order_ascending } }, as: :json
    assert_response 200
  end

  test "should destroy chart_type" do
    assert_difference('ChartType.count', -1) do
      delete record_url(records(:one)), as: :json
      delete chart_url(charts(:one)), as: :json
      delete chart_type_url(@chart_type), as: :json
    end

    assert_response 204
  end
end
