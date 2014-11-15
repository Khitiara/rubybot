# Rubybot

The ninth iteration of the ElrosBot project.

## Installation

Clone the repo

## Usage

From within the project directory, run

`bundle exec ruby rubybot.rb`

## Contributing

1. Fork it ( https://github.com/robotbrain/rubybot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Example config file
```json
{
  "bot": {
    "server": "irc.esper.net",
    "channels": [
      "#example"
    ],
    "nick": "#######",
    "realname": "#######",
    "sasl.username": "######",
    "sasl.password": "######",
    "user": "ElrosGem"
  },
  "twitter": {
    "consumer_key": "#######",
    "consumer_secret": "########",
    "access_key": "####-#######",
    "access_secret": "########"
  },
  "github_repos": {
    "user/repo": ["#example"]
  }
}
}
```
