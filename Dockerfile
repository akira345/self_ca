FROM ruby:latest
RUN apt-get update \
	&& apt-get install -y default-mysql-client postgresql-client sqlite3 nodejs --no-install-recommends \
	&& curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
	&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
	&& apt-get update \
	&& apt-get -y install yarn \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile* ./

RUN bundle install && gem install execjs

COPY . .
RUN bundle exec rake assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
