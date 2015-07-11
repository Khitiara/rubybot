FROM ruby:2.2.2

WORKDIR /rubybot
ADD . /rubybot

RUN bundle -j `nproc`

ENTRYPOINT ["/usr/local/bin/rake"]
CMD ["rubybot:run"]
