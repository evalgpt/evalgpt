# Use the latest Debian-based image as the base
FROM debian:latest

# Update the system and install necessary tools
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y curl wget git build-essential libssl-dev zlib1g-dev

# UnComment the following lines to install the language(s) you want to use
# Ruby is always installed
ARG INSTALL_NODE=true
ARG INSTALL_PYTHON=true
ARG INSTALL_C_CPP=true
ARG INSTALL_GO=true
ARG INSTALL_RUST=true
ARG INSTALL_LUA=true
ARG INSTALL_SWIFT=true

# Install Ruby
RUN apt-get install -y ruby-dev

# Install Node.js
RUN if [ "$INSTALL_NODE" = "true" ] ; then \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  apt-get install -y nodejs ; \
  fi

# Install Python
RUN if [ "$INSTALL_PYTHON" = "true" ] ; then \
  apt-get install -y python3 python3-pip && \
  ln -s /usr/bin/python3 /usr/bin/python ; \
  fi

# Install C and C++
RUN if [ "$INSTALL_C_CPP" = "true" ] ; then \
  apt-get install -y gcc g++ ; \
  fi

# Install Go
RUN if [ "$INSTALL_GO" = "true" ] ; then \
  curl -O https://dl.google.com/go/go1.16.3.linux-amd64.tar.gz && \
  tar -xvf go1.16.3.linux-amd64.tar.gz && \
  mv go /usr/local ; \
  fi
ENV PATH=$PATH:/usr/local/go/bin

# Install Rust
RUN if [ "$INSTALL_RUST" = "true" ] ; then \
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ; \
  fi
ENV PATH=$PATH:/root/.cargo/bin

# Install Lua
RUN if [ "$INSTALL_LUA" = "true" ] ; then \
  apt-get install -y lua5.3 ; \
  fi

# Install Swift
RUN if [ "$INSTALL_SWIFT" = "true" ] ; then \
  wget https://swift.org/builds/swift-5.4.1-release/ubuntu2004/swift-5.4.1-RELEASE/swift-5.4.1-RELEASE-ubuntu20.04.tar.gz && \
  tar xzf swift-5.4.1-RELEASE-ubuntu20.04.tar.gz && \
  mv swift-5.4.1-RELEASE-ubuntu20.04 /usr/share/swift ; \
  fi
ENV PATH=$PATH:/usr/share/swift/usr/bin

# Install required Ruby gems
COPY Gemfile /evalgptp/
WORKDIR /evalgptp
RUN gem install bundler && bundle install

RUN mkdir /evalgptp/output

RUN chmod 777 /evalgptp/output

# Copy your app into the container
COPY . /evalgptp

CMD [ "/bin/bash", "-c", "source .env && ruby evalgpt.rb --verbose" ]
