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

RUN bundle install

COPY . .
#RUN bundle exec rake assets:precompile
#RUN rails webpacker:install

EXPOSE 3000
# 初回インストール時はこれを有効化して、手動でrails webpacker:installする。
#CMD ["tail", "-f", "/dev/null"]
CMD ["rails", "server", "-b", "0.0.0.0"]
