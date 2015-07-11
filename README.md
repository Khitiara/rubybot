Rubybot
=======

The ```{x | x > 9, x <- Z}```th iteration of elrosbot.
This one is modular and here to stay!
Credits to [02JanDal](https://github.com/02Jandal) for refactoring everything and [RX14](https://github.com/RX14) for the github linker plugin!

Installation
------------
Clone the repo

Run ```bundle install``` to get the dependencies

Configuration
-------------
Run ```rake rubybot:create_config``` and follow the prompts to generate a default config in config.json, then tweak it at will.

Running
-------
Run ```rake rubybot:run``` to start it up! It expects a config.json in the current directory.

Docker
------
1. Clone the repo
1. Run `docker build -t rubybot .`
1. Run ```docker run -it -v `pwd`/config.json:/rubybot/config.json rubybot:create_config``` to generate the config or manually create your own.
1. Run ```docker run --name rubybot -v `pwd`/config.json:/rubybot/config.json rubybot``` to run the bot.
