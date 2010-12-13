require 'rubygems'
require 'rake'
require 'echoe'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

Echoe.new('ucb_confluence', '0.0.1') do |p|
  p.description    = "API for manipulating Confluence Users and Groups"
  p.url            = "http://ucbrb.rubyforge.org"
  p.author         = "Steven Hansen"
  p.email          = "runner@berkeley.edu"
  p.project        = "ucbrb"
  p.rdoc_pattern   = "README.md", "lib/**/**", "TODO.md"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
end

Spec::Rake::SpecTask.new("spec:rcov") do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
  t.rcov = true
end

RCov::VerifyTask.new(:rcov => "spec:rcov") do |t|
  t.threshold = 100
end


