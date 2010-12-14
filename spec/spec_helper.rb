require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'confluence'


CONFLUENCE_ENV = "test" unless defined?(CONFLUENCE_ENV)
UCB::LDAP::Person.include_test_entries = true

