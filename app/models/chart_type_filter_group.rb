# Links between chart types and filter groups, indicating that all charts of
# this chart type use this filter group.
#
# This m2m class goes in its own file (as opposed to say, the same file as
# ChartType) so that `rails c` ORM statements can actually find the class.
# Not sure if there is another use.
class ChartTypeFilterGroup < ApplicationRecord
  belongs_to :chart_type
  belongs_to :filter_group
end
