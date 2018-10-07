require 'test_helper'

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_1 = users(:one)
    @user_2 = users(:two)
    @game = games(:one)

    @chart_type_score = ChartType.create(name: "Score", format_spec: [{}], order_ascending: false, game: @game)
    @chart_group = ChartGroup.create(name: "Group 1", parent_group: nil, order_in_parent: 1, game: @game)
    @chart_1 = Chart.create(name: "Chart 1", chart_type: @chart_type_score, chart_group: @chart_group, order_in_group: 1)
    @chart_2 = Chart.create(name: "Chart 2", chart_type: @chart_type_score, chart_group: @chart_group, order_in_group: 2)
  end

  test "should get index" do
    record = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())

    get records_url, as: :json
    assert_response :success

    response_json = JSON.parse(response.body)
    # 1 record total
    assert_equal(1, response_json['data'].length)
    # Check for correct values
    record_0 = response_json['data'][0]
    assert_equal(record.id.to_s, record_0['id'])
    assert_equal('records', record_0['type'])
    assert_equal(10, record_0['attributes']['value'])
    assert_not_nil(record_0['attributes']['achieved-at'])
    assert_equal(
      @chart_1.id.to_s, record_0['relationships']['chart']['data']['id'])
    assert_equal('charts', record_0['relationships']['chart']['data']['type'])
    assert_equal(
      @user_1.id.to_s, record_0['relationships']['user']['data']['id'])
    assert_equal('users', record_0['relationships']['user']['data']['type'])
  end

  test "should get records of a particular chart" do
    record_c1_u1 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())
    record_c1_u2 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.now())
    record_c2_u1 = Record.create(value: 10, chart: @chart_2, user: @user_1, achieved_at: DateTime.now())

    get records_url(chart_id: @chart_1.id), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    # Only the records for chart 1
    assert_equal(2, records.length)
    # By default, latest-submitted record first
    assert_equal(record_c1_u2.id.to_s, records[0]['id'])
    assert_equal(record_c1_u1.id.to_s, records[1]['id'])
  end

  test "should get records of a particular user" do
    record_c1_u1 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())
    record_c1_u2 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.now())
    record_c2_u1 = Record.create(value: 10, chart: @chart_2, user: @user_1, achieved_at: DateTime.now())

    get records_url(user_id: @user_1.id), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    # Only the records for user 1
    assert_equal(2, records.length)
    # By default, latest-submitted record first
    assert_equal(record_c2_u1.id.to_s, records[0]['id'])
    assert_equal(record_c1_u1.id.to_s, records[1]['id'])
  end

  test "should get records of a chart-user combination" do
    record_c1_u1_1 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())
    record_c1_u1_2 = Record.create(value: 12, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())
    record_c1_u2 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.now())
    record_c2_u1 = Record.create(value: 10, chart: @chart_2, user: @user_1, achieved_at: DateTime.now())
    record_c2_u2 = Record.create(value: 10, chart: @chart_2, user: @user_2, achieved_at: DateTime.now())

    get records_url(chart_id: @chart_1.id, user_id: @user_1.id), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    # Only the chart 1, user 1 records
    assert_equal(2, records.length)
    # By default, latest-submitted record first
    assert_equal(record_c1_u1_2.id.to_s, records[0]['id'])
    assert_equal(record_c1_u1_1.id.to_s, records[1]['id'])
  end

  test "should sort by date submitted by default" do
    # Add some differently-ordered dates-achieved and values, to make sure
    # that other sorting methods cannot get the correct result.
    record_1 = Record.create(value: 12, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_2 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2018))
    record_3 = Record.create(value: 11, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2017))

    get records_url, as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_3.id.to_s, records[0]['id'])
    assert_equal(record_2.id.to_s, records[1]['id'])
    assert_equal(record_1.id.to_s, records[2]['id'])
  end

  test "should sort by date submitted when specified" do
    # Add some differently-ordered dates-achieved and values, to make sure
    # that other sorting methods cannot get the correct result.
    record_1 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_2 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2018))
    record_3 = Record.create(value: 12, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2017))

    get records_url(sort: 'date_submitted'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_3.id.to_s, records[0]['id'])
    assert_equal(record_2.id.to_s, records[1]['id'])
    assert_equal(record_1.id.to_s, records[2]['id'])
  end

  test "should sort by date achieved" do
    record_2016 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_2018 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2018))
    record_2017 = Record.create(value: 12, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2017))

    get records_url(sort: 'date_achieved'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_2018.id.to_s, records[0]['id'])
    assert_equal(record_2017.id.to_s, records[1]['id'])
    assert_equal(record_2016.id.to_s, records[2]['id'])
  end

  test "should sort by value in same chart" do
    record_11 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2018))
    record_12 = Record.create(value: 12, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2017))

    get records_url(chart_id: @chart_1.id, sort: 'value'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(record_11.id.to_s, records[1]['id'])
    assert_equal(record_10.id.to_s, records[2]['id'])
  end

  test "should sort by value in ascending-direction chart" do
    chart_type_low_score = ChartType.create(name: "Low score", format_spec: [{}], order_ascending: true, game: @game)
    chart = Chart.create(name: "Chart 3", chart_type: chart_type_low_score, chart_group: @chart_group, order_in_group: 3)
    record_62 = Record.create(value: 62, chart: chart, user: @user_1, achieved_at: DateTime.new(2016))
    record_61 = Record.create(value: 61, chart: chart, user: @user_2, achieved_at: DateTime.new(2018))
    record_63 = Record.create(value: 63, chart: chart, user: @user_2, achieved_at: DateTime.new(2017))

    get records_url(chart_id: chart.id, sort: 'value'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_61.id.to_s, records[0]['id'])
    assert_equal(record_62.id.to_s, records[1]['id'])
    assert_equal(record_63.id.to_s, records[2]['id'])
  end

  test "should sort by value across charts, using any chart's sort order" do
    # It doesn't make sense to sort by value across ascending and descending
    # chart types.
    # So we'll only test when they're all asc or all desc. In this case, desc.
    record_11 = Record.create(value: 11, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2018))
    record_12 = Record.create(value: 12, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2017))

    get records_url(sort: 'value'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    # Check sort order
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(record_11.id.to_s, records[1]['id'])
    assert_equal(record_10.id.to_s, records[2]['id'])
  end

  test "should respond with error about unrecognized sort method" do
    get records_url(sort: 'chart'), as: :json
    assert_response :bad_request

    errors = JSON.parse(response.body)['errors']
    assert_equal(1, errors.length)
    assert_equal("Unrecognized sort method: chart", errors[0]['detail'])
  end

  test "should rank records, showing one per user" do
    record_11 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2018))
    record_12 = Record.create(value: 12, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2017))

    # This query would be used to show who has the best record for chart 1.
    # User A is 1st with this record, user B is 2nd with this record, etc.
    get records_url(sort: 'value', chart_id: @chart_1.id, ranked_entity: 'user'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(2, records.length)
    # user 2's record
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(1, records[0]['attributes']['rank'])
    # user 1's record
    assert_equal(record_11.id.to_s, records[1]['id'])
    assert_equal(2, records[1]['attributes']['rank'])
  end

  test "should rank records, showing one per chart" do
    record_11 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2018))
    record_12 = Record.create(value: 12, chart: @chart_2, user: @user_1, achieved_at: DateTime.new(2017))

    # This query would be used to show which of user 1's records are largest
    # and smallest by value. e.g. which levels yield the highest score or take
    # the longest time for user 1.
    # Records should be ranked in the same direction that the individual charts
    # rank their records.
    get records_url(sort: 'value', user_id: @user_1.id, ranked_entity: 'chart'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(2, records.length)
    # chart 2
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(1, records[0]['attributes']['rank'])
    # chart 1
    assert_equal(record_11.id.to_s, records[1]['id'])
    assert_equal(2, records[1]['attributes']['rank'])
  end

  test "rank numbers should support ties, tiebreaking by date achieved" do
    record_u1 = Record.create(value: 12, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2017))
    record_u2 = Record.create(value: 11, chart: @chart_1, user: @user_2, achieved_at: DateTime.new(2016))
    record_u3 = Record.create(value: 11, chart: @chart_1, user: users(:three), achieved_at: DateTime.new(2015))
    record_u4 = Record.create(value: 10, chart: @chart_1, user: users(:four), achieved_at: DateTime.new(2018))

    # This query would be used to show which of user 1's records are largest
    # and smallest by value. e.g. which levels yield the highest score or take
    # the longest time for user 1.
    get records_url(sort: 'value', chart_id: @chart_1.id, ranked_entity: 'user'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(4, records.length)
    # user 1
    assert_equal(record_u1.id.to_s, records[0]['id'])
    assert_equal(1, records[0]['attributes']['rank'])
    # user 3 (tied with 2, but achieved first)
    assert_equal(record_u3.id.to_s, records[1]['id'])
    assert_equal(2, records[1]['attributes']['rank'])
    # user 2 (achieved after user 3)
    assert_equal(record_u2.id.to_s, records[2]['id'])
    assert_equal(2, records[2]['attributes']['rank'])
    # user 4
    assert_equal(record_u4.id.to_s, records[3]['id'])
    assert_equal(4, records[3]['attributes']['rank'])
  end

  test "should respond with error about unrecognized ranked_entity option" do
    get records_url(ranked_entity: 'record'), as: :json
    assert_response :bad_request

    errors = JSON.parse(response.body)['errors']
    assert_equal(1, errors.length)
    assert_equal("Unrecognized ranked_entity option: record", errors[0]['detail'])
  end

  test "should flag improvements" do
    record_11 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2017))
    record_12 = Record.create(value: 12, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2018))

    get records_url(sort: 'date_achieved', chart_id: @chart_1.id, improvements: 'flag'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(3, records.length)
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(true, records[0]['attributes']['is-improvement'])
    assert_equal(record_10.id.to_s, records[1]['id'])
    assert_equal(false, records[1]['attributes']['is-improvement'])
    assert_equal(record_11.id.to_s, records[2]['id'])
    assert_equal(true, records[2]['attributes']['is-improvement'])
  end

  test "should filter to only improvements" do
    record_11 = Record.create(value: 11, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2016))
    record_10 = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2017))
    record_12 = Record.create(value: 12, chart: @chart_1, user: @user_1, achieved_at: DateTime.new(2018))

    get records_url(sort: 'date_achieved', chart_id: @chart_1.id, improvements: 'filter'), as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(2, records.length)
    assert_equal(record_12.id.to_s, records[0]['id'])
    assert_equal(record_11.id.to_s, records[1]['id'])
  end

  test "should respond with error about unrecognized improvements option" do
    get records_url(sort: 'date_achieved', chart_id: @chart_1.id, improvements: 'highlight'), as: :json
    assert_response :bad_request

    errors = JSON.parse(response.body)['errors']
    assert_equal(1, errors.length)
    assert_equal("Unrecognized improvements option: highlight", errors[0]['detail'])
  end

  test "should respond with error about the improvements option needing a chart specified" do
    get records_url(sort: 'date_achieved', improvements: 'flag'), as: :json
    assert_response :bad_request

    errors = JSON.parse(response.body)['errors']
    assert_equal(1, errors.length)
    assert_equal("To use the 'improvements' option, you must sort by date, and you must specify a chart_id.", errors[0]['detail'])
  end

  test "should respond with error about the improvements option needing sorting by date" do
    get records_url(sort: 'value', chart_id: @chart_1.id, improvements: 'flag'), as: :json
    assert_response :bad_request

    errors = JSON.parse(response.body)['errors']
    assert_equal(1, errors.length)
    assert_equal("To use the 'improvements' option, you must sort by date, and you must specify a chart_id.", errors[0]['detail'])
  end

  test "should support basic single-number record displays" do
    record = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())

    get records_url, as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(1, records.length)
    assert_equal("10", records[0]['attributes']['value-display'])
  end

  test "should support suffix option in record displays" do
    chart_type_kmh = ChartType.create(name: "km/h", format_spec: [{"suffix": " km/h"}], order_ascending: false, game: @game)
    chart = Chart.create(name: "Chart 3", chart_type: chart_type_kmh, chart_group: @chart_group, order_in_group: 3)
    record = Record.create(value: 10, chart: chart, user: @user_1, achieved_at: DateTime.now())

    get records_url, as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(1, records.length)
    assert_equal("10 km/h", records[0]['attributes']['value-display'])
  end

  test "should support multi-number record displays with specified multipliers" do
    chart_type_milli = ChartType.create(name: "Milli time", format_spec: [{"multiplier": 60, "suffix": "'"}, {"multiplier": 1000, "suffix": '"'}, {}], order_ascending: true, game: @game)
    chart = Chart.create(name: "Chart 3", chart_type: chart_type_milli, chart_group: @chart_group, order_in_group: 3)
    record = Record.create(value: 63456, chart: chart, user: @user_1, achieved_at: DateTime.now())

    get records_url, as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(1, records.length)
    assert_equal("1'3\"456", records[0]['attributes']['value-display'])
  end

  test "should support digits option in record displays" do
    chart_type_milli = ChartType.create(name: "Milli time", format_spec: [{"multiplier": 60, "suffix": "'"}, {"multiplier": 1000, "suffix": '"', "digits": 2}, {"digits": 3}], order_ascending: true, game: @game)
    chart = Chart.create(name: "Chart 3", chart_type: chart_type_milli, chart_group: @chart_group, order_in_group: 3)
    record = Record.create(value: 63006, chart: chart, user: @user_1, achieved_at: DateTime.now())

    get records_url, as: :json
    assert_response :success

    records = JSON.parse(response.body)['data']
    assert_equal(1, records.length)
    assert_equal("1'03\"006", records[0]['attributes']['value-display'])
  end

  test "should create record" do
    assert_difference('Record.count') do
      post records_url, params: { record: {
        value: 10,
        chart_id: @chart_1.id,
        user_id: @user_1.id,
        achieved_at: DateTime.now(),
      } }, as: :json
    end

    assert_response 201
  end

  test "should show record" do
    record = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())

    get record_url(record), as: :json
    assert_response :success
  end

  test "should update record" do
    record = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())

    patch record_url(record), params: { record: {
        value: 14,
        chart_id: @chart_2.id,
        user_id: @user_2.id,
      } }, as: :json
    assert_response 200
  end

  test "should destroy record" do
    record = Record.create(value: 10, chart: @chart_1, user: @user_1, achieved_at: DateTime.now())

    assert_difference('Record.count', -1) do
      delete record_url(record), as: :json
    end

    assert_response 204
  end
end
