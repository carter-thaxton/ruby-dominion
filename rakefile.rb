task :default => :test

task :test do
  require File.dirname(__FILE__) + '/test/test_cards.rb'  
end
