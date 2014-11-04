source 'https://rubygems.org'

gem 'cinch', '~>2.1.0'
gem 'rack', '~>1.1'
gem 'sinatra'
gem 'git.io', '~> 0.0.3'

Dir['plugins/**/Gemfile'].each do |gemfile|
  self.send(:eval, File.open(gemfile, 'r').read)
end
