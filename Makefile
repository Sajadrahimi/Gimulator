-include .env

COMMIT := $(shell git rev-parse --short HEAD)
VERSION := $(shell git describe --always --tags ${COMMIT})

ifeq ($(OS),Windows_NT)
	PROJECTNAME := $(shell for /F "delims=" %%i in ("%cd%") do @echo %%~ni)
else
	PROJECTNAME := $(shell basename "$(PWD)")
endif

IMG ?= xerac/gimulator:${VERSION}


# Go related variables.
ifeq ($(OS),Windows_NT)
	GOBASE := $(shell cd)
	GOFILES := $(shell dir /s /B ${GOBASE} | findstr /i .go)
	GOMAIN := $(GOBASE)\cmd\gimulator\main.go
	BINDIR := $(GOBASE)\bin
else
	GOBASE := $(shell pwd)
    GOFILES := $(shell find $(GOBASE) -type f -name "*.go")
    GOMAIN := $(GOBASE)/cmd/gimulator/main.go
    BINDIR := $(GOBASE)/bin
endif

# Use linker flags to provide version/build settings
ifeq ($(OS),Windows_NT)
	LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(COMMIT) -extldflags=\"-static\""
else
	LDFLAGS=-ldflags '-X=main.Version=$(VERSION) -X=main.Build=$(COMMIT) -extldflags="-static"'
endif

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent

.PHONY: fmt dep get test clean build run exec
win-fmt:
	@echo ">>>  Formatting project"
	go fmt .\...

fmt:
	@echo ">>>  Formatting project"
	go fmt ./...

dep:
	@echo ">>>  Add missing and remove unused modules..."
	go mod tidy

win-get: dep
	@echo ">>>  Checking if there is any missing dependencies..."
	go get -u .\...

get: dep
	@echo ">>>  Checking if there is any missing dependencies..."
	go get -u ./...

win-test: build clean
	@echo ">>>  Testing..."
	go test .\...

test: build clean
	@echo ">>>  Testing..."
	go test ./...

clean:
	@echo ">>>  Cleaning build cache"
	-rm -r $(BINDIR) 2> /dev/null
	go clean ./...

win-build:
	@echo ">>>  Building binary..."
	if not exist $(BINDIR) mkdir $(BINDIR)
	@echo "go build $(LDFLAGS) -o $(BINDIR)\\$(PROJECTNAME) $(GOMAIN)"
	go build $(LDFLAGS) -o $(BINDIR)\\$(PROJECTNAME) $(GOMAIN)

build:
	@echo ">>>  Building binary..."
	mkdir -p $(BINDIR) 2> /dev/null
	go build $(LDFLAGS) -o $(BINDIR)/$(PROJECTNAME) $(GOMAIN)


run:
	@echo ">>>  Running..."
	go run $(GOMAIN)

win-exec: build
	@echo ">>>  Executing binary..."
	@$(BINDIR)\$(PROJECTNAME)

exec: build
	@echo ">>>  Executing binary..."
	@$(BINDIR)/$(PROJECTNAME)

docker-build: build
	@echo ">>>  Building docker image..."
	docker build -t $(IMG) .

docker-push: docker-build
	@echo ">>>  Pushing docker image..."
	docker push $(IMG)
