# contained_mr

[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/pwnall/contained_mr/master/frames)
[![Build Status](https://travis-ci.org/pwnall/contained_mr.svg?branch=master)](https://travis-ci.org/pwnall/contained_mr)

Map-Reduce where both the mappers and the reducer run inside Docker containers.

## Development Environment

`contained-mr` requires access to a Docker daemon. The easiest way to
bring up a development setup is to install
[Docker Machine](https://github.com/docker/machine) and
[VirtualBox](https://www.virtualbox.org/).

The commands below install the prerequisites on OSX using
[Homebrew](http://brew.sh/).

```bash
brew install brew-cask docker docker-machine
brew cask install virtualbox
```

Create a Docker VM. This is a one-time setup.

```bash
docker-machine create --driver virtualbox dev
```

Set up the local environment to point to the Docker daemon in the VM. This must
be executed in every shell where `contained-mr` is used.

```bash
eval "$(docker-machine env dev)"
```

### Cleanup

When tests go wrong, they often leave dead containers and images behind.
Removing all stopped containers and all unused images is a big stick that works
quite well in development environments.

```bash
docker ps --all --quiet --no-trunc | xargs docker rm
docker images --quiet --no-trunc | xargs docker rmi
```


## Contributing to contained_mr

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2015 Victor Costan. See LICENSE.txt for further details.
