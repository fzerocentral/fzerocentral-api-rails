# This m2m class goes in its own file (as opposed to say, the same file as
# ChartType) so that `rails c` ORM statements can actually find the class.
# Not sure if there is another use.
class ChartTypeFilterGroup < ApplicationRecord
  belongs_to :chart_type
  belongs_to :filter_group
  default_scope { order(order_in_chart_type: :asc) }
end
