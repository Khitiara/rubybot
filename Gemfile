source 'https://rubygems.org'

gem 'cinch', '~>2.1.0'
gem 'rack', '~>1.1'
gem 'timers', '~>4.0.1'
gem 'activesupport'
gem 'revolver', '~> 1.1.1'
gem 'yajl-ruby'
gem 'commander'

Dir['plugins/**/Gemfile'].each do |gemfile|
  self.send(:eval, File.open(gemfile, 'r').read)
end
