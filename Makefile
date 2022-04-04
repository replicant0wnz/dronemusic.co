SHELL := /bin/bash

DOCKER=docker
DOCKER_CONTAINER=node
SOURCE_PATH=`pwd`
WORKING_PATH=/usr/src/app
DIST_PATH=dist
PACKAGE="dist.tar.gz"

# Docker build command
BUILD=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH) $(DOCKER_CONTAINER)

init:
	$(BUILD) npm install

build:
	$(BUILD) npm run build 

package:
	tar cfvz $(PACKAGE) $(DIST_PATH)

release:
	gh release create $(version) dist.tar.gz -F CHANGELOG.md

clean:
	rm -rf node_modules dist dist.tar.gz

all: init build package
