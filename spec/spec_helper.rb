require 'rubygems'
require 'bundler'
Bundler.setup


$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'confluence'


CONFLUENCE_ENV = "test" unless defined?(CONFLUENCE_ENV)
UCB::LDAP::Person.include_test_entries = true

