require 'test_helper'

class FilterImplicationLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filter_group = filter_groups(:one)
    @filter_dolphin = Filter.create(
      name: "Dolphin", filter_group: @filter_group, order_in_group: 1)
    @filter_bizhawk = Filter.create(
      name: "Bizhawk", filter_group: @filter_group, order_in_group: 2)
    @filter_emulator = Filter.create(
      name: "Emulator", filter_group: @filter_group, order_in_group: 3)
    @link = FilterImplicationLink.create(
      implying_filter: @filter_dolphin, implied_filter: @filter_emulator)
  end

  test "should get index" do
    params = {filter_group_id: @filter_group.id}
    get filter_implication_links_url(params), as: :json
    assert_response :success
  end

  test "should show filter implication link" do
    get filter_implication_link_url(@link), as: :json
    assert_response :success

    # Check field values
    link = JSON.parse(response.body)['data']
    assert_equal(
      @filter_dolphin.id.to_s,
      link['relationships']['implying-filter']['data']['id'])
    assert_equal(
      @filter_emulator.id.to_s,
      link['relationships']['implied-filter']['data']['id'])
  end

  test "should create filter implication link" do
    assert_difference('FilterImplicationLink.count') do
      post filter_implication_links_url, params: {
        data: {
          relationships: {
            'implying-filter': { data: {
              type: 'filters', id: @filter_bizhawk.id } },
            'implied-filter': { data: {
              type: 'filters', id: @filter_emulator.id } },
          },
          type: 'filter-implication-links',
        },
      }, as: :json
    end
    assert_response :created

    # Check field values
    link = FilterImplicationLink.find(JSON.parse(response.body)['data']['id'])
    assert_equal(@filter_bizhawk.id, link.implying_filter.id)
    assert_equal(@filter_emulator.id, link.implied_filter.id)
  end

  test "should update filter implication link" do
    patch filter_implication_link_url(@link), params: {
      data: {
        relationships: {
          'implying-filter': { data: {
            type: 'filters', id: @filter_bizhawk.id } },
          'implied-filter': { data: {
            type: 'filters', id: @filter_emulator.id } },
        },
        type: 'filter-implication-links',
      },
    }, as: :json
    assert_response :success

    # Check field values
    @link.reload
    assert_equal(@filter_bizhawk.id, @link.implying_filter.id)
    assert_equal(@filter_emulator.id, @link.implied_filter.id)
  end

  test "should destroy filter implication link" do
    assert_difference('FilterImplicationLink.count', -1) do
      delete filter_implication_link_url(@link), as: :json
    end
    assert_response :no_content
  end
end
