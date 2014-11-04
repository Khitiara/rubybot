source 'https://rubygems.org'

gem 'cinch', '~>2.1.0'
gem 'rack', '~>1.1'

Dir['plugins/**/Gemfile'].each do |gemfile|
  self.send(:eval, File.open(gemfile, 'r').read)
end
