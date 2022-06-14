SHELL := /bin/bash

# Global stuff
DOCKER=docker
SOURCE_PATH := $(shell pwd)
WORKING_PATH=/usr/src/app
DIST_PATH=dist
PACKAGE="dist.tar.gz"
CONFIG="makefile.json"

# jq config
JQ_CONTAINER=imega/jq
JQ=$(DOCKER) run -i $(JQ_CONTAINER) -c

# Node config
NODE_CONTAINER=node
NODE=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH) -e BUILD_VERSION=$(version) $(NODE_CONTAINER)

# nginx config
NGINX_CONTAINER=nginx
NGINX=$(DOCKER) run -v $(SOURCE_PATH)/dist:/usr/share/nginx/html -p 8080:80 --name nginx -d $(NGINX_CONTAINER)

# Robot config
ROBOT_CONTAINER=ppodgorsek/robot-framework:latest
ROBOT=$(DOCKER) run --network host -e ROBOT_OPTIONS="--xunit xunit/output --variable BUILD_VERSION:$(version)" -v $(SOURCE_PATH)/tests:/opt/robotframework/tests -v $(SOURCE_PATH)/reports:/opt/robotframework/reports $(ROBOT_CONTAINER)

# Github config
GH_CONTAINER=ghcr.io/supportpal/github-gh-cli
GH=$(DOCKER) run -e GH_TOKEN=$$GH_TOKEN -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH) $(GH_CONTAINER)

# AWS config
AWS_CONTAINER=amazon/aws-cli
AWS_WORKING_PATH=/aws
AWS=$(DOCKER) run -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID 

# Items from $(CONFIG)
S3_BUCKET := $(shell cat $(CONFIG) | $(JQ) .aws.s3.destination)
S3_REGION := $(shell cat $(CONFIG) | $(JQ) .aws.s3.region)
DISTRIBUTION_ID := $(shell cat $(CONFIG) | $(JQ) .aws.cloudfront.distribution_id)
INVALIDATION_PATH := $(shell cat $(CONFIG) | $(JQ) .aws.cloudfront.invalidation_path) 

init:
	$(NODE) npm install --legacy-peer-deps

build:
	$(NODE) npm run build 

package:
	tar cfvz $(PACKAGE) $(DIST_PATH)

nginx_start:
	$(NGINX) 

nginx_stop: 
	$(DOCKER) stop nginx
	$(DOCKER) rm nginx

test:
	mkdir -p $(SOURCE_PATH)/reports/xunit && chmod -R 777 $(SOURCE_PATH)/reports
	$(ROBOT)

release:
	$(GH) gh release create $(version) dist.tar.gz --generate-notes

deploy:
	cd dist ; \
	$(AWS) -v $(SOURCE_PATH)/dist:$(AWS_WORKING_PATH) -w $(AWS_WORKING_PATH) $(AWS_CONTAINER)  s3 sync . s3://$(S3_BUCKET) --delete --acl public-read --region $(S3_REGION)

invalidate:
	INVALIDATION=`$(AWS) $(AWS_CONTAINER) cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths $(INVALIDATION_PATH) --region $(S3_REGION)` ; \
	echo $$INVALIDATION ; \
	INVALIDATION_ID=`echo $$INVALIDATION | $(JQ) -r .Invalidation.Id` ; \
	$(AWS) $(AWS_CONTAINER) cloudfront wait invalidation-completed --distribution-id $(DISTRIBUTION_ID) --id $$INVALIDATION_ID

clean:
	rm -rf node_modules dist dist.tar.gz package-lock.json reports

all: init build nginx_start test nginx_stop package
