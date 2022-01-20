# fzerocentral-api-rails

Old project; replaced with https://github.com/fzerocentral/fzerocentral-api because the primary maintainer at this time is more familiar with Django than Rails.


## Installation for development environments

* Clone this repository
* Install Ruby
* Install PostgreSQL
* `cd` into the root of this repository and run `bundle` to install the required Ruby gems
* Create an `.env` file at the root of this repository, and specify configuration variable values. Here are the variables you need to define:

  ```
  FZCAPI_DATABASE_NAME=your_database_name_here
  FZCAPI_DATABASE_USERNAME=username_to_access_this_database
  FZCAPI_DATABASE_PASSWORD=password_for_this_username
  FZCAPI_TEST_DATABASE_NAME=database_name_for_running_automated_tests
  FZCAPI_TEST_DATABASE_USERNAME=username_to_access_this_database
  FZCAPI_TEST_DATABASE_PASSWORD=password_for_this_username
  SECRET_KEY_BASE=673j3g938jh98j23rijgt93i...<more letters/numbers>
  TEST_SECRET_KEY_BASE=698u30yu5uyhj530u30u99u8...<more letters/numbers>
  ```

  The secret keys should be generated with a `rails secret` command run from the root of this repository.

* From the root of this repository, run:
  * `rails db:create` (creates the databases)
  * `rails db:migrate` (runs the database migrations)
  * `rails server` (runs the server)
* In a web browser, navigate to the server URL given in the output of `rails server`, and ensure that you get a response.


## Very brief overview

Obviously, knowing Ruby on Rails will go a long way towards understanding this codebase. For those not very familiar with Rails, you can at least find the database models at `db/schema.rb`, and the URL/endpoint definitions at `config/routes.rb` (see the [Rails guide on routing](https://guides.rubyonrails.org/routing.html) for details).

Games and Users sit at the top of the database-relationships hierarchy. So, create those first, then create the other objects as allowed by foreign key constraints.
