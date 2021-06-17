REPO := caruccio
APP_VERSION := 1.0.0

build:
	docker build -t $(REPO)/app:$(APP_VERSION) --build-arg APP_VERSION=$(APP_VERSION) $(PWD)

run: stop
	docker run --name app -d --rm -p 8080:80 $(REPO)/app:$(APP_VERSION) $(COMMAND)

stop:
	docker rm -f app

push:
	docker push $(REPO)/app:$(APP_VERSION)

release all: build push
