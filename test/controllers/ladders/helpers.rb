def filter_ladder_params(
    game: nil, kind: nil, order: nil,
    chart_group: nil, name: nil, filter_spec: nil)
  # Note how tests only need to pass in `order` instead of
  # order_in_game_and_kind, for brevity.
  return {
    game: game, kind: kind, order_in_game_and_kind: order,
    chart_group: chart_group, name: name, filter_spec: filter_spec}
end

def ladder_params_hash(params_in, with_defaults: false)
  params = filter_ladder_params(params_in)

  if with_defaults
    if params[:kind].nil?
      params[:kind] = 'main'
    end
    if params[:name].nil?
      params[:name] = 'New ladder'
    end
    if params[:filter_spec].nil?
      params[:filter_spec] = '1-2n'
    end
  end

  return params
end

def ladder_params_json(params_in, with_defaults: false)
  params = ladder_params_hash(params_in, with_defaults: with_defaults)

  attributes = {}
  if !params[:name].nil?
    attributes[:name] = params[:name]
  end
  if !params[:kind].nil?
    attributes[:kind] = params[:kind]
  end
  if !params[:filter_spec].nil?
    attributes['filter-spec'] = params[:filter_spec]
  end
  if !params[:order_in_game_and_kind].nil?
    attributes['order-in-game-and-kind'] = params[:order_in_game_and_kind]
  end

  relationships = {}
  if !params[:chart_group].nil?
    relationships['chart-group'] = {
      data: {
        type: 'chart-groups', id: params[:chart_group].id,
      },
    }
  end
  if !params[:game].nil?
    relationships['game'] = {
      data: {
        type: 'games', id: params[:game].id,
      },
    }
  end

  return {data: {
    attributes: attributes, relationships: relationships, type: 'ladders'}}
end

def orm_create_ladder(params_in)
  params_hash = ladder_params_hash(params_in, with_defaults: true)
  return Ladder.create(params_hash)
end

def create_ladder(ladders_url, params_in)
  # Use default values on any unspecified non-foreign-key values.
  params = ladder_params_json(params_in, with_defaults: true)
  post ladders_url, params: params, as: :json

  if response.status == 201
    return get_created_ladder
  end
end

def get_created_ladder
  # Last response is assumed to be from a successful ladder creation.
  ladder_id = JSON.parse(response.body)['data']['id']
  ladder = Ladder.find(ladder_id)
  return ladder
end

def update_ladder(ladder_url, params_in)
  params = ladder_params_json(params_in, with_defaults: false)
  patch ladder_url, params: params, as: :json
end

def assert_field_error(pointer, detail)
  error = JSON.parse(response.body)['errors'][0]
  assert_equal(pointer, error['source']['pointer'])
  assert_equal(detail, error['detail'])
end
