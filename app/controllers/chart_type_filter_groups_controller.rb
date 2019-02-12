class ChartTypeFilterGroupsController < ApplicationController
  before_action :set_ctfg, only: [:show, :update, :destroy]

  # GET /chart_type_filter_groups
  def index
    @ctfgs = ChartTypeFilterGroup.all

    if params.key?(:chart_type_id)
      @ctfgs = @ctfgs.where(
        chart_type_id: params[:chart_type_id])
    end
    if params.key?(:filter_group_id)
      @ctfgs = @ctfgs.where(
        filter_group_id: params[:filter_group_id])
    end

    render json: @ctfgs.order(order_in_chart_type: :asc)
  end

  # GET /chart_type_filter_groups/1
  def show
    render json: @ctfg
  end

  # POST /chart_type_filter_groups
  def create
    @ctfg = ChartTypeFilterGroup.new(ctfg_params)

    ChartTypeFilterGroup.transaction do
      chart_type_ctfgs = ChartTypeFilterGroup.where(
        chart_type: @ctfg.chart_type)

      if @ctfg.order_in_chart_type == nil
        # By default, order at the end, after all existing CTFGs.
        @ctfg.order_in_chart_type = chart_type_ctfgs.length + 1
      else
        # Restrict the order to the accepted range.
        if @ctfg.order_in_chart_type < 1
          @ctfg.order_in_chart_type = 1
        elsif @ctfg.order_in_chart_type > chart_type_ctfgs.length + 1
          @ctfg.order_in_chart_type = chart_type_ctfgs.length + 1
        end

        # Change other CTFGs' order as needed to accommodate the new CTFG. We
        # need to +1 the order of CTFGs coming after this one (in highest to
        # lowest order to avoid order conflicts), and then insert this CTFG.
        later_chart_type_ctfgs = ChartTypeFilterGroup \
          .where(chart_type: @ctfg.chart_type) \
          .where(ChartTypeFilterGroup.arel_table[:order_in_chart_type].gteq(
            @ctfg.order_in_chart_type)) \
          .order(order_in_chart_type: :desc)
        later_chart_type_ctfgs.each do |ctfg|
          ctfg.update(order_in_chart_type: ctfg.order_in_chart_type + 1)
        end
      end

      if @ctfg.save
        render json: @ctfg, status: :created, location: @ctfg
      else
        render json: @ctfg.errors, status: :unprocessable_entity
        # Since we potentially did multiple DB changes (including updating
        # the order of other CTFGs) in preparation for the new CTFG, we should
        # roll back the transaction if the CTFG save fails.
        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /chart_type_filter_groups/1
  def update
    ChartTypeFilterGroup.transaction do
      chart_type_ctfgs = ChartTypeFilterGroup.where(
        chart_type: @ctfg.chart_type)

      if ctfg_params.key?(:order_in_chart_type)

        old_order = @ctfg.order_in_chart_type
        new_order = ctfg_params[:order_in_chart_type]

        # To fix the order of the other CTFGs while avoiding order conflicts,
        # first we set this CTFG's order to 0, then we inc/dec the order of
        # CTFGs between this CTFG's old and new order, then we set this CTFG
        # to the desired order.

        if old_order < new_order

          @ctfg.update(order_in_chart_type: 0)

          # e.g. ABCDEF -> ABDEFC (moved C)
          # CTFGs in between the old and new positions move backward.
          # Update from lowest to highest.
          affected_chart_type_ctfgs = ChartTypeFilterGroup \
            .where(chart_type: @ctfg.chart_type) \
            .where(
              ChartTypeFilterGroup.arel_table[:order_in_chart_type].gt(
                old_order).and(
              ChartTypeFilterGroup.arel_table[:order_in_chart_type].lteq(
                new_order))) \
            .order(order_in_chart_type: :asc)
          affected_chart_type_ctfgs.each do |ctfg|
            ctfg.update(order_in_chart_type: ctfg.order_in_chart_type - 1)
          end

        elsif new_order < old_order

          @ctfg.update(order_in_chart_type: 0)

          # e.g. ABCDEF -> ABFCDE (moved F)
          # CTFGs in between the old and new positions move forward.
          # Update from highest to lowest.
          affected_chart_type_ctfgs = ChartTypeFilterGroup \
            .where(chart_type: @ctfg.chart_type) \
            .where(
              ChartTypeFilterGroup.arel_table[:order_in_chart_type].lt(
                old_order).and(
              ChartTypeFilterGroup.arel_table[:order_in_chart_type].gteq(
                new_order))) \
            .order(order_in_chart_type: :desc)
          affected_chart_type_ctfgs.each do |ctfg|
            ctfg.update(order_in_chart_type: ctfg.order_in_chart_type + 1)
          end

        end

      end

      if @ctfg.update(ctfg_params)
        render json: @ctfg
      else
        render json: @ctfg.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      # Restrict the order to the accepted range.
      if @ctfg.order_in_chart_type < 1
        @ctfg.update(order_in_chart_type: 1)
      elsif @ctfg.order_in_chart_type > chart_type_ctfgs.length
        @ctfg.update(order_in_chart_type: chart_type_ctfgs.length)
      end
    end
  end

  # DELETE /chart_type_filter_groups/1
  def destroy
    ChartTypeFilterGroup.transaction do
      # To fix the order of the other CTFGs while avoiding order conflicts,
      # first we delete this CTFG, then we -1 the order of CTFGs coming after
      # this one (in lowest to highest order).
      @ctfg.destroy

      later_chart_type_ctfgs = ChartTypeFilterGroup \
        .where(chart_type: @ctfg.chart_type) \
        .where(ChartTypeFilterGroup.arel_table[:order_in_chart_type].gteq(
          @ctfg.order_in_chart_type)) \
        .order(order_in_chart_type: :asc)
      later_chart_type_ctfgs.each do |ctfg|
        ctfg.update(order_in_chart_type: ctfg.order_in_chart_type - 1)
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ctfg
      @ctfg = ChartTypeFilterGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def ctfg_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters.
        only: ['chart-type', 'filter-group', 'order-in-chart-type',
          'show-by-default'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end
end
