# This m2m class goes in its own file (as opposed to say, the same file as
# Filter) so that `rails c` ORM statements can actually find the class.
# Not sure if there is another use.
class FilterImplication < ApplicationRecord
  belongs_to :implying_filter, foreign_key: "implying_filter_id", class_name: "Filter"
  belongs_to :implied_filter, foreign_key: "implied_filter_id", class_name: "Filter"
end
