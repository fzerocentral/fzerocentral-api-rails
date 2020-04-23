class LaddersController < ApplicationController
  before_action :set_ladder, only: [:show, :update, :destroy]

  # GET /ladders
  def index
    @ladders = Ladder.all

    if params.key?(:game_id)
      @ladders = @ladders.where(game_id: params[:game_id])
    end
    if params.key?(:kind)
      @ladders = @ladders.where(kind: params[:kind])
    end

    @ladders = @ladders.order(
      game_id: :asc, kind: :asc, order_in_game_and_kind: :asc, name: :asc)

    render json: @ladders
  end

  # GET /ladders/1
  def show
    render json: @ladder
  end

  # POST /ladders
  def create
    @ladder = Ladder.new(create_params)

    # To keep things really simple, we don't take an order param upon
    # creation. We just order at the end, after other ladders.
    game_and_kind_ladders = Ladder.where(
      game: @ladder.game, kind: @ladder.kind)
    @ladder.order_in_game_and_kind = game_and_kind_ladders.length + 1

    if @ladder.save
      render json: @ladder, status: :created, location: @ladder
    else
      render_resource_with_validation_errors(@ladder)
    end
  end

  # PATCH/PUT /ladders/1
  def update
    # Use a transaction because updating order might involve updating
    # multiple objects.
    Ladder.transaction do
      game_and_kind_ladders = Ladder.where(
        game: @ladder.game, kind: @ladder.kind)

      if update_params.key?(:order_in_game_and_kind)

        old_order = @ladder.order_in_game_and_kind
        new_order = update_params[:order_in_game_and_kind]

        # To fix the order of the other ladders while avoiding order conflicts,
        # first we set this ladder's order to 0, then we inc/dec the order of
        # ladders between this ladder's old and new order, then we set this ladder
        # to the desired order.

        if old_order < new_order

          @ladder.update(order_in_game_and_kind: 0)

          # e.g. ABCDEF -> ABDEFC (moved C)
          # Ladders in between the old and new positions move backward.
          # Update from lowest to highest.
          ladders_that_must_move = Ladder \
            .where(game: @ladder.game, kind: @ladder.kind) \
            .where(
            Ladder.arel_table[:order_in_game_and_kind].gt(
              old_order).and(
              Ladder.arel_table[:order_in_game_and_kind].lteq(
                new_order))) \
            .order(order_in_game_and_kind: :asc)
          ladders_that_must_move.each do |ladder|
            ladder.update(
              order_in_game_and_kind: ladder.order_in_game_and_kind - 1)
          end

        elsif new_order < old_order

          @ladder.update(order_in_game_and_kind: 0)

          # e.g. ABCDEF -> ABFCDE (moved F)
          # Ladders in between the old and new positions move forward.
          # Update from highest to lowest.
          ladders_that_must_move = Ladder \
            .where(game: @ladder.game, kind: @ladder.kind) \
            .where(
            Ladder.arel_table[:order_in_game_and_kind].lt(
              old_order).and(
              Ladder.arel_table[:order_in_game_and_kind].gteq(
                new_order))) \
            .order(order_in_game_and_kind: :desc)
          ladders_that_must_move.each do |ladder|
            ladder.update(
              order_in_game_and_kind: ladder.order_in_game_and_kind + 1)
          end

        end

      end

      if @ladder.update(update_params)
        # Restrict the order to the accepted range.
        if @ladder.order_in_game_and_kind < 1
          @ladder.update(order_in_game_and_kind: 1)
        elsif @ladder.order_in_game_and_kind > game_and_kind_ladders.length
          @ladder.update(order_in_game_and_kind: game_and_kind_ladders.length)
        end

        render json: @ladder
      else
        render_resource_with_validation_errors(@ladder)
        raise ActiveRecord::Rollback
      end
    end
  end

  # DELETE /ladders/1
  def destroy
    Ladder.transaction do
      # To fix the order of the other ladders while avoiding order conflicts,
      # first we delete this ladder, then we -1 the order of ladders coming
      # after this one (in lowest to highest order).
      @ladder.destroy

      later_ladders = Ladder \
        .where(game: @ladder.game, kind: @ladder.kind) \
        .where(Ladder.arel_table[:order_in_game_and_kind].gteq(
        @ladder.order_in_game_and_kind)) \
        .order(order_in_game_and_kind: :asc)
      later_ladders.each do |ladder|
        ladder.update(
          order_in_game_and_kind: ladder.order_in_game_and_kind - 1)
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ladder
      @ladder = Ladder.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    # Don't accept an order param upon creation, only upon update.
    def create_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters. `only` is applied before `key_transform`, so we
        # must specify `'chart-group'` instead of `:chart_group`.
        only: [
          :name, :kind, 'filter-spec', 'chart-group', 'game'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end

    # To order updates simple for now, don't allow updating the game or kind of
    # a ladder. If that really needs to be done, it can be done with direct
    # ActiveRecord calls on the shell.
    def update_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        only: [
          :name, 'filter-spec', 'chart-group', 'order-in-game-and-kind'],
        key_transform: :underscore)
    end
end
