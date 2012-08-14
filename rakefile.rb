task :default => :test

task :test do
  $: << File.dirname(__FILE__) + '/test'
  
  require 'test_setup'
  require 'test_game'
  require 'test_big_money'
  require 'test_cards'
end
