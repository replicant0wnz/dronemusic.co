SHELL := /bin/bash

# Global stuff
DOCKER=docker
SOURCE_PATH := $(shell pwd)
WORKING_PATH=/usr/src/app
DIST_PATH=dist
PACKAGE="dist.tar.gz"

# Node config
NODE_CONTAINER=node
BUILD=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH) $(NODE_CONTAINER)

# Github config
GH_CONTAINER=ghcr.io/supportpal/github-gh-cli
GH=$(DOCKER) run -e GH_TOKEN=$$GH_TOKEN -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH) $(GH_CONTAINER)

# AWS config
AWS_CONTAINER=amazon/aws-cli
AWS_WORKING_PATH=/aws
S3_BUCKET=www.dronemusic.co
AWS=$(DOCKER) run -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID 
DISTRIBUTION_ID=E3K58SB4UNLCAE
INVALIDATION_PATH="/*"

# jq config
JQ_CONTAINER=imega/jq
JQ=$(DOCKER) run -i $(JQ_CONTAINER) -c

init:
	$(BUILD) npm install

build:
	$(BUILD) npm run build 

package:
	tar cfvz $(PACKAGE) $(DIST_PATH)

release:
	$(GH) gh release create $(version) dist.tar.gz --generate-notes

deploy:
	cd dist ; \
	$(AWS) -v $(SOURCE_PATH)/dist:$(AWS_WORKING_PATH) -w $(AWS_WORKING_PATH) $(AWS_CONTAINER)  s3 sync . s3://$(S3_BUCKET) --acl public-read

invalidate:
	$(AWS) $(AWS_CONTAINER) cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths $(INVALIDATION_PATH)

clean:
	rm -rf node_modules dist dist.tar.gz

all: init build package
