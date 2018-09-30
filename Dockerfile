FROM ruby:latest
RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile* ./

RUN bundle install && gem install execjs
COPY . .

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
