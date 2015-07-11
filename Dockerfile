FROM ruby:2.2.2

WORKDIR /rubybot
ADD . /rubybot

RUN bundle

ENTRYPOINT ["/usr/local/bin/rake"]
CMD ["rubybot:run"]
