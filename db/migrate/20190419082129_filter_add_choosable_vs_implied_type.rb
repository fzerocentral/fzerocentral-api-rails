class FilterAddChoosableVsImpliedType < ActiveRecord::Migration[5.2]
  def change
    # 'choosable' vs. 'implied' filter type.
    #
    # choosable means that the filter can be chosen directly when submitting
    # a record: e.g. this record was achieved with Blue Falcon.
    # implied means it can't be chosen when submitting a record. It is
    # implied by a subset of choosable filters: e.g. this record was achieved
    # with Blue Falcon, which is a non-custom machine, and therefore the
    # Non-Custom filter is implied to apply.
    #
    # The previous plan was to distinguish between choosable vs. implied
    # purely based on whether the filter had implications targeting it or not.
    # However, this would lead to filters switching between choosable and
    # implied during implication management (addition/deletion of implications)
    # which seems like confusing behavior.
    # This field allows one to define filters as choosable or implied, in
    # advance of specifying the implications themselves.
    add_column :filters, :usage_type, :string, default: 'choosable'
  end
end
