FROM alpine:3.7
LABEL maintainer="Joel Gilley jgilley@chegg.com"

# use rbenv understandable version
ARG RUBY_VERSION
ENV RUBY_VERSION=${RUBY_VERSION:-2.5.0}

# Set the timezone
# Load ash profile on launch
# Set rbenv in PATH for build
# Set ruby ops for build
ENV TIMEZONE=UTC \
	ENV=/etc/profile \
	RBENV_ROOT=/usr/local/rbenv \
	PATH=/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH \
	RUBY_CONFIGURE_OPTS=--disable-install-doc \
	APP_ENV=development \
	RAILS_ENV=development \
	PAGER='busybox less'

ENV ac_cv_func_isnan=yes \
	ac_cv_func_isinf=yes

# Install the required services dumb-init.  Also install and fix timezones / ca-certificates
# Install the build depenencies and libraries for building rbenv and ruby as a virtual package
# Install nginx, bash and openssl
# copy timzone data to a good place
# set the timezone
# delete the tz package
# update central authority certs
# delete the default ngix config
# set up pretty colours for shell access
# add in my old skool alias for dir
# make sure to source any additions to ~/.profile if something adds them
# make the /app and /run/nginx directories
# set up the user we're going to use for nginx
# make /run/nginx owned by that user
# make /app group the nginx user
# let the nginx group read/write on /app
RUN apk --update --no-cache add dumb-init tzdata ca-certificates nginx bash openssl libffi && \
	apk --update --no-cache add --virtual node nodejs nodejs-npm && \
	apk --update --no-cache add --virtual build-deps git curl python \
	build-base linux-headers readline-dev openssl-dev zlib-dev libffi-dev && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    apk del tzdata && \
    update-ca-certificates && \
    rm -rf /etc/nginx/conf.d/default.conf && \
    mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh && \
    echo alias dir=\'ls -alh --color\' >> /etc/profile && \
    echo 'source ~/.profile' >> /etc/profile && \
    mkdir -p /app /run/nginx && \
	adduser -u 82 -D -S -G www-data www-data && \
	chown -R nginx:www-data /run/nginx && \
	chown -R :www-data /app && \
	chmod -R g+rw /app

# From now on we/re going to be working from /app
WORKDIR /app

# install rbenv
# setup the environment
# check with the doctor
# install ruby
# install puma and bundler, and we run as root so silence that warning
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
	cd ${RBENV_ROOT} && \
	src/configure && \
	make -C src && \
	echo 'export RUBY_CONFIGURE_OPTS=--disable-install-doc' >> ~/.profile && \
	echo 'export PATH="${RBENV_ROOT}/bin:$PATH"' >> ~/.profile && \
	echo 'eval "$(rbenv init -)"' >> ~/.profile && \
	echo 'gem: --no-document' >> ~/.gemrc && \
	git clone --depth 1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build  && \
	curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash && \
	rbenv install -v ${RUBY_VERSION} && \
	rbenv global ${RUBY_VERSION} && \
	gem install bundler puma && \
	bundle config git.allow_insecure true && \
	bundle config --global silence_root_warning 1

ENV YARN_VERSION=latest

RUN curl -sfSL -O https://yarnpkg.com/${YARN_VERSION}.tar.gz -O https://yarnpkg.com/${YARN_VERSION}.tar.gz.asc && \
      mkdir /usr/local/share/yarn && \
      tar -xf ${YARN_VERSION}.tar.gz -C /usr/local/share/yarn --strip 1 && \
      ln -s /usr/local/share/yarn/bin/yarn /usr/local/bin/ && \
      ln -s /usr/local/share/yarn/bin/yarnpkg /usr/local/bin/ && \
      rm ${YARN_VERSION}.tar.gz*;


# Add the container config files
COPY ./container_configs /

# Copy over the code Gemfile and run the install
COPY ./code/Gemfile ./
RUN chmod a+x /start-servers.sh && \
	bundle install

# remove the build system
# likely you're going to use your own Dockerfile inheriting this image
# and repeat the above COPY and RUN to do your install
# so this should probably be the last thing you run
# RUN apk del build-deps

# Finally copy over the app
COPY ./code/ ./

# expose our service port
EXPOSE 80

# start with our PID 1 controller
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/bin/sh", "-c", "/start-servers.sh"]