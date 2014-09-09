# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
puts "!!!!!!!!!!!!"
puts ENV["FACEBOOK_KEY"]
ENV["FACEBOOK_KEY"] = "334523600058919"
ENV["FACEBOOK_SECRET"] = "fc60480ab600e1002cd42ed598448f6d"