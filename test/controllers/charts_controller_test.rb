require 'test_helper'

class ChartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chart = charts(:one)
  end

  test "should get index" do
    get charts_url, as: :json
    assert_response :success
  end

  test "should create chart" do
    assert_difference('Chart.count') do
      post charts_url, params: { chart: { leaf_chart_group_id: @chart.leaf_chart_group_id, name: @chart.name } }, as: :json
    end

    assert_response 201
  end

  test "should show chart" do
    get chart_url(@chart), as: :json
    assert_response :success
  end

  test "should update chart" do
    patch chart_url(@chart), params: { chart: { leaf_chart_group_id: @chart.leaf_chart_group_id, name: @chart.name } }, as: :json
    assert_response 200
  end

  test "should destroy chart" do
    assert_difference('Chart.count', -1) do
      delete chart_url(@chart), as: :json
    end

    assert_response 204
  end
end
