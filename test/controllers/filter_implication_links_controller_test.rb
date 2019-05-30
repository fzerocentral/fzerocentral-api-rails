require 'test_helper'

class FilterImplicationLinksControllerTest < ActionDispatch::IntegrationTest
  def create_filter(name, usage_type)
    return Filter.create(
      name: name, filter_group: @filter_group, usage_type: usage_type)
  end

  def create_link(implying_filter, implied_filter)
    post filter_implication_links_url, params: {
      data: {
        relationships: {
          'implying-filter': { data: {
            type: 'filters', id: implying_filter.id } },
          'implied-filter': { data: {
            type: 'filters', id: implied_filter.id } },
        },
        type: 'filter-implication-links',
      },
    }, as: :json
    new_link_data = JSON.parse(response.body)['data']
    if new_link_data
      return FilterImplicationLink.find(new_link_data['id'])
    else
      return nil
    end
  end

  def delete_link(implying_filter, implied_filter)
    link = FilterImplicationLink.find_by(
      implying_filter: implying_filter, implied_filter: implied_filter)
    delete filter_implication_link_url(link), as: :json
  end

  def get_fis_as_filter_id_pairs()
    fis = FilterImplication.all
    return fis.map{|fi| [fi.implying_filter.id, fi.implied_filter.id]}
  end

  def link_exists(implying_filter, implied_filter)
    link = FilterImplicationLink.find_by(
      implying_filter: implying_filter, implied_filter: implied_filter)
    return link.present?
  end

  def implication_exists(implying_filter, implied_filter)
    implication = FilterImplication.find_by(
      implying_filter: implying_filter, implied_filter: implied_filter)
    return implication.present?
  end

  # Returns true if the set of FilterImplications in the database
  # exactly matches the expected_implications parameter; false otherwise.
  # Params:
  # +expected_implications+:: array of arrays of Filters:
  #   [[implying filter 1, implied filter 1], [implying filter 2,
  #   implied filter 2], ...]
  def implication_set_matches(expected_implications)
    actual_implications = FilterImplication.all
    actual_fi_id_pairs = actual_implications \
      .map{|fi| [fi.implying_filter.id, fi.implied_filter.id]}
    expected_fi_id_pairs = expected_implications \
      .map{|fi| [fi[0].id, fi[1].id]}

    actual_in_expected = actual_fi_id_pairs \
      .map{|pair| expected_fi_id_pairs.include?(pair)}

    return actual_in_expected.all? \
      && (actual_fi_id_pairs.length == expected_fi_id_pairs.length)
  end

  setup do
    @filter_group = filter_groups(:one)

    @cf1 = create_filter("Gallant Star-G4", 'choosable')
    @cf2 = create_filter("Gallant Cannon-G4", 'choosable')
    @cf3 = create_filter("Omega Gantlet-V2", 'choosable')
    @cf4 = create_filter("Tornado Gantlet-V2", 'choosable')

    @if1 = create_filter("Maximum Star cockpit", 'implied')
    @if2 = create_filter("Combat Cannon cockpit", 'implied')
    @if3 = create_filter("Titan-G4 booster", 'implied')
    @if4 = create_filter("Thunderbolt-V2 booster", 'implied')
    @if5 = create_filter("A custom cockpit", 'implied')
    @if6 = create_filter("B custom booster", 'implied')
    @if7 = create_filter("A custom booster", 'implied')
    @if8 = create_filter("Custom", 'implied')

    @filter_group_2 = filter_groups(:two)
    @fg2_cf1 = Filter.create(
      name: "Gamecube", filter_group: @filter_group_2, usage_type: 'choosable')
    @fg2_if1 = Filter.create(
      name: "Console", filter_group: @filter_group_2, usage_type: 'implied')
  end

  test "should get index by filter group" do
    create_link(@cf1, @if1)
    create_link(@fg2_cf1, @fg2_if1)

    params = {filter_group_id: @filter_group.id}
    get filter_implication_links_url(params), as: :json
    assert_response :success

    # Check values
    links = JSON.parse(response.body)['data']
    assert_equal(1, links.length)
    assert_equal(
      @cf1.id.to_s, links[0]['relationships']['implying-filter']['data']['id'])
    assert_equal(
      @if1.id.to_s, links[0]['relationships']['implied-filter']['data']['id'])
  end

  test "should get index by implying filter" do
    create_link(@cf1, @if1)
    create_link(@cf3, @if1)

    params = {implying_filter_id: @cf1.id}
    get filter_implication_links_url(params), as: :json
    assert_response :success

    # Check values
    links = JSON.parse(response.body)['data']
    assert_equal(1, links.length)
    assert_equal(
      @cf1.id.to_s, links[0]['relationships']['implying-filter']['data']['id'])
    assert_equal(
      @if1.id.to_s, links[0]['relationships']['implied-filter']['data']['id'])
  end

  test "should get index by implied filter" do
    create_link(@cf1, @if1)
    create_link(@cf1, @if2)

    params = {implied_filter_id: @if1.id}
    get filter_implication_links_url(params), as: :json
    assert_response :success

    # Check values
    links = JSON.parse(response.body)['data']
    assert_equal(1, links.length)
    assert_equal(
      @cf1.id.to_s, links[0]['relationships']['implying-filter']['data']['id'])
    assert_equal(
      @if1.id.to_s, links[0]['relationships']['implied-filter']['data']['id'])
  end

  test "getting index with no params should get an error" do
    create_link(@cf1, @if1)

    params = {}
    get filter_implication_links_url(params), as: :json
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal(false, error.has_key?('source'))
    assert_equal(
      "Must specify a filter_group_id, implying_filter_id, or" \
      " implied_filter_id.",
      error['detail'])
  end

  test "should show filter implication link" do
    @link = create_link(@cf1, @if1)

    get filter_implication_link_url(@link), as: :json
    assert_response :success

    # Check field values
    link = JSON.parse(response.body)['data']
    assert_equal(
      @cf1.id.to_s,
      link['relationships']['implying-filter']['data']['id'])
    assert_equal(
      @if1.id.to_s,
      link['relationships']['implied-filter']['data']['id'])
  end

  test "should create filter implication link" do
    assert_difference('FilterImplicationLink.count') do
      post filter_implication_links_url, params: {
        data: {
          relationships: {
            'implying-filter': { data: {
              type: 'filters', id: @cf1.id } },
            'implied-filter': { data: {
              type: 'filters', id: @if1.id } },
          },
          type: 'filter-implication-links',
        },
      }, as: :json
    end
    assert_response :created

    # Check field values
    link = FilterImplicationLink.find(JSON.parse(response.body)['data']['id'])
    assert_equal(@cf1.id, link.implying_filter.id)
    assert_equal(@if1.id, link.implied_filter.id)
  end

  test "should properly create a choosable-implied link (properly meaning creating applicable implications as well)" do
    create_link(@cf1, @if1)

    assert(link_exists(@cf1, @if1))
    assert(implication_set_matches([
      [@cf1, @if1],
    ]))
  end

  test "should properly create an implied-implied link" do
    create_link(@cf1, @if1)
    create_link(@if1, @if2)

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@if1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
    ]))
  end

  test "should properly create links tying one choosable filter to two implied" do
    create_link(@cf1, @if1)
    create_link(@cf1, @if2)

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
    ]))
  end

  test "should properly create links tying two choosable filters to one implied" do
    create_link(@cf1, @if1)
    create_link(@cf2, @if1)

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf2, @if1))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf2, @if1],
    ]))
  end

  test "should properly create link tying multiple choosable to multiple implied" do
    # CF1, CF2 -> IF1 =>
    #                    IF2 -> IF3
    #             CF3 ->
    #
    # (=> is the last link to be added)
    # The purpose of CF3 in this test is to allow creating the IF2 -> IF3 link
    # before the IF1 -> IF2 link. Without CF3, the IF2 -> IF3 link would be
    # a unused link and therefore disallowed at that point.
    create_link(@cf1, @if1)
    create_link(@cf2, @if1)
    create_link(@cf3, @if2)
    create_link(@if2, @if3)
    create_link(@if1, @if2)

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf2, @if1))
    assert(link_exists(@cf3, @if2))
    assert(link_exists(@if2, @if3))
    assert(link_exists(@if1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
      [@cf1, @if3],
      [@cf2, @if1],
      [@cf2, @if2],
      [@cf2, @if3],
      [@cf3, @if2],
      [@cf3, @if3],
    ]))
  end

  test "should disallow creating a duplicate link" do
    create_link(@cf1, @if1)
    assert_response :created
    create_link(@cf1, @if1)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "There is already a link from #{@cf1.name} to #{@if1.name}.",
      error['detail'])

    assert(link_exists(@cf1, @if1))
    assert(implication_set_matches([
      [@cf1, @if1],
    ]))
  end

  test "should disallow creating a link between filters of different filter groups" do
    create_link(@cf1, @fg2_if1)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "Can't create a link between filters of different groups.",
      error['detail'])

    assert_not(link_exists(@cf1, @fg2_if1))
    assert(implication_set_matches([]))
  end

  test "should disallow creating a link to a choosable filter" do
    create_link(@cf1, @cf2)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "Can't create a link pointing to a choosable filter.", error['detail'])

    assert_not(link_exists(@cf1, @cf2))
    assert(implication_set_matches([]))
  end

  test "should disallow creating a link that would be unused" do
    create_link(@if1, @if2)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "This link is not allowed because it would currently be unused: it" \
      " won't connect any choosable filters to any other filter. Unused" \
      " links are disallowed because they make it harder to check that the" \
      " filter graph is still a multitree.",
      error['detail'])

    assert_not(link_exists(@if1, @if2))
    assert(implication_set_matches([]))
  end

  test "should disallow creating a link to form a diamond (2 different paths from A to B)" do
    #     -> IF1 ->
    # CF1           IF3
    #     -> IF2 =>
    #
    # (=> is the last link to be added, thus creating 2 paths from CF1 to IF3)
    create_link(@cf1, @if1)
    assert_response :created
    create_link(@cf1, @if2)
    assert_response :created
    create_link(@if1, @if3)
    assert_response :created
    create_link(@if2, @if3)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "This link is not allowed because it would create a second path from" \
      " #{@cf1.name} to #{@if3.name}. This restriction is in place to ensure" \
      " that the filter graph is still a multitree.",
      error['detail'])

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf1, @if2))
    assert(link_exists(@if1, @if3))
    assert_not(link_exists(@if2, @if3))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
      [@cf1, @if3],
    ]))
  end

  test "should disallow creating a link to form a cycle" do
    # CF1 -> IF1 -> IF2
    #         ^     |
    #        IF3 <--
    #
    # This is just a special case of '2 different paths from A to B', in which
    # A and B are the same node.
    # This case is also interesting because, if the graph checks
    # are implemented too naively, this may trigger an infinite loop.
    create_link(@cf1, @if1)
    assert_response :created
    create_link(@if1, @if2)
    assert_response :created
    create_link(@if2, @if3)
    assert_response :created
    create_link(@if3, @if1)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "This link is not allowed because it would create a second path from" \
      " #{@cf1.name} to #{@if1.name}. This restriction is in place to" \
      " ensure that the filter graph is still a multitree.",
      error['detail'])

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@if1, @if2))
    assert(link_exists(@if2, @if3))
    assert_not(link_exists(@if3, @if1))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
      [@cf1, @if3],
    ]))
  end

  test "should destroy filter implication link" do
    @link = create_link(@cf1, @if1)

    assert_difference('FilterImplicationLink.count', -1) do
      delete filter_implication_link_url(@link), as: :json
    end
    assert_response :no_content
  end

  test "should properly delete a choosable -> implied link" do
    create_link(@cf1, @if1)
    assert(link_exists(@cf1, @if1))

    delete_link(@cf1, @if1)
    assert_not(link_exists(@cf1, @if1))
    assert(implication_set_matches([]))
  end

  test "should properly delete an implied -> implied link" do
    create_link(@cf1, @if1)
    create_link(@if1, @if2)
    assert(link_exists(@cf1, @if1))
    assert(link_exists(@if1, @if2))

    delete_link(@if1, @if2)
    assert(link_exists(@cf1, @if1))
    assert_not(link_exists(@if1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
    ]))
  end

  test "should properly delete a link tying multiple choosable to multiple implied" do
    # CF1, CF2 -> IF1 =>
    #                    IF2 -> IF3
    #             CF3 ->
    #
    # (=> gets deleted)
    create_link(@cf1, @if1)
    create_link(@cf2, @if1)
    create_link(@cf3, @if2)
    create_link(@if2, @if3)
    create_link(@if1, @if2)
    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf2, @if1))
    assert(link_exists(@cf3, @if2))
    assert(link_exists(@if2, @if3))
    assert(link_exists(@if1, @if2))

    delete_link(@if1, @if2)
    assert(link_exists(@cf1, @if1))
    assert(link_exists(@cf2, @if1))
    assert(link_exists(@cf3, @if2))
    assert(link_exists(@if2, @if3))
    assert_not(link_exists(@if1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf2, @if1],
      [@cf3, @if2],
      [@cf3, @if3],
    ]))
  end

  test "should disallow a link-deletion which would render another link unused" do
    create_link(@cf1, @if1)
    create_link(@if1, @if2)
    assert(link_exists(@cf1, @if1))
    assert(link_exists(@if1, @if2))

    delete_link(@cf1, @if1)
    assert_response :bad_request

    error = JSON.parse(response.body)['errors'][0]
    assert_equal('/data/attributes/base', error['source']['pointer'])
    assert_equal(
      "This link-deletion is not allowed because there still exist links from" \
      " #{@if1.name} that would be rendered unused: they wouldn't connect" \
      " any choosable filters to any other filter. Unused links are" \
      " disallowed because they make it harder to check that the filter" \
      " graph is still a multitree.",
      error['detail'])

    assert(link_exists(@cf1, @if1))
    assert(link_exists(@if1, @if2))
    assert(implication_set_matches([
      [@cf1, @if1],
      [@cf1, @if2],
    ]))
  end
end
