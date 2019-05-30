class FilterImplicationLinksController < ApplicationController
  before_action :set_filter_implication_link, only: [:show, :update, :destroy]

  # GET /filter_implication_links
  def index
    if params.key?(:filter_group_id)
      # Implying filter should be in this filter group.
      # (Filters of different filter groups should never be linked, so this
      # should also mean the implied filter is in this group.)
      @links = FilterImplicationLink.joins(:implying_filter) \
        .where(filters: {filter_group_id: params[:filter_group_id]})
    elsif params.key?(:implying_filter_id)
      @links = FilterImplicationLink.where(
        implying_filter_id: params[:implying_filter_id])
    elsif params.key?(:implied_filter_id)
      @links = FilterImplicationLink.where(
        implied_filter_id: params[:implied_filter_id])
    else
      render_general_validation_error(
        "Must specify a filter_group_id, implying_filter_id, or" \
        " implied_filter_id.")
      return
    end

    # Order by implying filter's name, then implied filter's name.
    # Unfortunately, using table aliases with joins in ActiveRecord seems
    # to require raw SQL or Arel syntax. We've picked raw SQL here.
    @links = @links \
      .joins("INNER JOIN filters AS implying_filters ON implying_filters.id = filter_implication_links.implying_filter_id") \
      .joins("INNER JOIN filters AS implied_filters ON implied_filters.id = filter_implication_links.implied_filter_id") \
      .order('implying_filters.name ASC') \
      .order('implied_filters.name ASC')

    render json: @links
  end

  # GET /filter_implication_links/1
  def show
    render json: @link
  end

  # POST /filter_implication_links
  def create
    @link = FilterImplicationLink.new(link_params)

    # Update effective filter implications, given that we're creating a link
    # from filter A to filter B.
    # Note that these filter implications can only originate at choosable
    # filters.
    filter_A = Filter.find(link_params[:implying_filter_id])
    filter_B = Filter.find(link_params[:implied_filter_id])

    existing_link = FilterImplicationLink.find_by(
      implying_filter: filter_A, implied_filter: filter_B)
    if ! existing_link.nil?
      @link.errors.add(:base,
        "There is already a link from #{filter_A.name} to #{filter_B.name}.")
      render_resource_with_validation_errors(@link)
      return
    end

    if filter_A.filter_group.id != filter_B.filter_group.id
      @link.errors.add(:base,
        "Can't create a link between filters of different groups.")
      render_resource_with_validation_errors(@link)
      return
    end

    if filter_B.usage_type == 'choosable'
      @link.errors.add(:base,
        "Can't create a link pointing to a choosable filter.")
      render_resource_with_validation_errors(@link)
      return
    end

    choosable_filters_reaching_A = choosable_filters_reaching_A(filter_A)
    if choosable_filters_reaching_A.empty?
      @link.errors.add(:base,
        "This link is not allowed because it would currently be unused: it" \
        " won't connect any choosable filters to any other filter. Unused" \
        " links are disallowed because they make it harder to check that the" \
        " filter graph is still a multitree.")
      render_resource_with_validation_errors(@link)
      return
    end

    filters_reachable_from_B = filters_reachable_from_B(filter_B)

    FilterImplicationLink.transaction do
      # Every choosable filter reaching A now implies every filter that B
      # reaches.
      choosable_filters_reaching_A.each do |filter_X|
        filters_reachable_from_B.each do |filter_Y|

          existing_fi = FilterImplication.find_by(
            implying_filter: filter_X, implied_filter: filter_Y)
          if existing_fi.present?
            @link.errors.add(:base,
              "This link is not allowed because it would create a second" \
              " path from #{filter_X.name} to #{filter_Y.name}. This" \
              " restriction is in place to ensure that the filter graph is" \
              " still a multitree.")
            render_resource_with_validation_errors(@link)
            raise ActiveRecord::Rollback
            return
          end

          fi = FilterImplication.new(
            implying_filter: filter_X, implied_filter: filter_Y)
          if !fi.save
            render json: fi.errors, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
        end
      end

      if @link.save
        render json: @link, status: :created, location: @link
      else
        render_resource_with_validation_errors(@link)
        # Since we potentially did multiple DB changes (FIs as well as this
        # FIL), we should roll back the transaction if the FIL save fails.
        raise ActiveRecord::Rollback
      end
    end
  end

  # DELETE /filter_implication_links/1
  def destroy

    # Update effective filter implications, given that we're deleting the link
    # from filter A to filter B.
    filter_A = @link.implying_filter
    filter_B = @link.implied_filter
    choosable_filters_reaching_A = choosable_filters_reaching_A(filter_A)
    filters_reachable_from_B = filters_reachable_from_B(filter_B)

    FilterImplicationLink.transaction do
      # Since we have a multitree, if there is an implication path from X to Y
      # which uses the A -> B link, then that is the only path from X to Y.
      # Therefore, by deleting the A -> B link, X no longer implies Y.
      # Stated more succinctly: Every choosable filter reaching A no longer
      # implies any filter that B reaches.
      choosable_filters_reaching_A.each do |filter_X|
        filters_reachable_from_B.each do |filter_Y|
          filter_implication = FilterImplication.find_by(
            implying_filter: filter_X, implied_filter: filter_Y)
          filter_implication.destroy
        end
      end

      implications_to_B = FilterImplication.find_by(implied_filter: filter_B)
      links_from_B = FilterImplicationLink.find_by(implying_filter: filter_B)
      if implications_to_B.nil? && (! links_from_B.nil?)
        @link.errors.add(:base,
          "This link-deletion is not allowed because there still exist links" \
          " from #{filter_B.name} that would be rendered unused: they" \
          " wouldn't connect any choosable filters to any other filter." \
          " Unused links are disallowed because they make it harder to check" \
          " that the filter graph is still a multitree.")
        render_resource_with_validation_errors(@link)
        raise ActiveRecord::Rollback
        return
      end

      @link.destroy
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filter_implication_link
      @link = FilterImplicationLink.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def link_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters. `only` is applied before `key_transform`, so we
        # must specify `'implying-filter'` instead of `:implying_filter`.
        only: ['implying-filter', 'implied-filter'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end

    def choosable_filters_reaching_A(filter_A)
      if filter_A.usage_type == 'choosable'
        return [filter_A]
      else
        fis_toward_A = FilterImplication.where(implied_filter: filter_A)
        return fis_toward_A.map{|fi| fi.implying_filter}
      end
    end

    def filters_reachable_from_B(filter_B)
      # Breadth-first search to find all the filters reachable from B
      result = [filter_B]
      bfs_current_step_filters = [filter_B]

      while bfs_current_step_filters.length > 0
        bfs_next_step_filters = []
        bfs_current_step_filters.each do |filter_X|
          links_from_X = FilterImplicationLink.where(
            implying_filter: filter_X)
          filters_linked_from_X = links_from_X.map{|link| link.implied_filter}
          filters_linked_from_X.each do |filter_Y|
            # Since the filter graph should be a multitree, it should be
            # guaranteed that we haven't visited this filter yet.
            result.push(filter_Y)
            bfs_next_step_filters.push(filter_Y)
          end
        end
        bfs_current_step_filters = bfs_next_step_filters
      end

      return result
    end
end
