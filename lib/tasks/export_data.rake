# Command to import/export database data. Usage:
#
# Export data from existing database to seed file:
# - `rails export:export_to_seeds > db/seeds.rb`
#
# Import data from seed file to new database:
# - Change your /.env file to the database name/details you want to load into
# - `rails db:create`
# - `rails db:migrate`
# - `rake db:seed`

namespace :export do
  desc "Export data"
  task :export_to_seeds => :environment do
    # Model objects must be added in an order which doesn't violate foreign
    # key constraints.
    # This means handling the model classes in a good order, and it also means
    # adding objects within the same class in a good order if there are any
    # self-referential FK fields (ordering by primary key should work).
    models = [User, Game, ChartType, ChartGroup, Chart, FilterGroup, Filter, ChartTypeFilterGroup, FilterImplication, FilterImplicationLink, Record, RecordFilter, Ladder]
    models.each do |model|
      # Order this model's objects by primary key, and iterate.
      model.all.order(id: :asc).each do |obj|
        excluded_keys = ['created_at', 'updated_at']
        serialized = obj
          .as_json
          .delete_if{|key,value| excluded_keys.include?(key)}
        # Write a line of Ruby which will add this model object.
        puts "#{model}.create(#{serialized})"
      end
    end
  end
end
