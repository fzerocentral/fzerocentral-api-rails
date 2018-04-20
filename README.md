# F-Zero Central API (test project)

Still trying to figure out Ruby on Rails, so this is just a test project for now.

If by chance, this actually ends up being a decent project that we should keep working on to create the actual FZC API, then we can fork this to the fzerocentral group.


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
