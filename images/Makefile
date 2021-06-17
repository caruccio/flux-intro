DOCKER_REPO := caruccio
DOCKER_IMAGE := app
APP_VERSION := 1.0.0

log:
	@echo "$$(tput setaf 3; tput bold) -> $(DOCKER_REPO)/$(DOCKER_IMAGE):$(APP_VERSION)$$(tput sgr0)"

build: log
	docker build -t $(DOCKER_REPO)/$(DOCKER_IMAGE):$(APP_VERSION) --build-arg APP_VERSION=$(APP_VERSION) $(PWD)

run: log stop
	docker run --name app -d --rm -p 8080:80 $(DOCKER_REPO)/$(DOCKER_IMAGE):$(APP_VERSION) $(COMMAND)

stop: log
	docker rm -f app

push: log
	docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):$(APP_VERSION)

release all: build push
