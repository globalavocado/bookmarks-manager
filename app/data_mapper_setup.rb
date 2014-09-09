env = ENV["RACK_ENV"] || "development"
# we're telling datamapper to user a postgres database on localhost. The name will be "bookmark_manager_test" or "bookmark_manager_development" depending on the environment
DataMapper.setup(:default, "postgres://localhost/bookmark_manager_#{env}")

#After declaring your models, you should finalise them
DataMapper.finalize
