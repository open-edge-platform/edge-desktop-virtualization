# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

BINARY_NAME ?= device-plugin
PKG_LIST := $(shell go list ./... | grep -v /vendor/)
DOCKER_REPO ?= localhost:5000
BUILD_NAME ?= intel-idv-$(BINARY_NAME)
HELM_CHART_NAME ?= mdp
BUILD_VERSION ?= v1
DOCKER_IMAGE ?= $(DOCKER_REPO)/$(BUILD_NAME):$(BUILD_VERSION)

# Go commands
GO ?= go

.PHONY: all build clean test coverage coverage-html docker-build docker-push deploy undeploy lint fmt tidy vendor

all: clean build

build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build -o $(BINARY_NAME) cmd/main.go

clean:
	rm -f $(BINARY_NAME)
	rm -rf coverage.out coverage.html

test:
	$(GO) test -v -cover $(PKG_LIST)

coverage:
	$(GO) test -coverprofile=coverage.out $(PKG_LIST)
	@echo "Coverage report generated at coverage.out"

coverage-html: coverage
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "HTML coverage report generated at coverage.html"

docker-build: build
	docker build --no-cache -t $(DOCKER_IMAGE) .

docker-push:
	docker push $(DOCKER_IMAGE)

deploy:
	helm install $(HELM_CHART_NAME) deploy/helm/maverikflats-device-plugin

undeploy:
	helm uninstall $(HELM_CHART_NAME)

lint:
	@if ! command -v golangci-lint > /dev/null; then \
		echo "golangci-lint not found, installing..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.55.2; \
	fi
	golangci-lint run ./...

fmt:
	$(GO) fmt ./...
	$(GO) vet ./...

tidy:
	$(GO) mod tidy

vendor:
	$(GO) mod vendor

# Run all checks
check: fmt lint test coverage

# For local development
run: build
	./$(BINARY_NAME)

# Print help
help:
	@echo "Common targets:"
	@echo "  build           Build the device plugin binary"
	@echo "  clean           Remove build artifacts"
	@echo "  test            Run all tests"
	@echo "  coverage        Generate test coverage report"
	@echo "  coverage-html   Generate HTML test coverage report"
	@echo "  docker-build    Build the Docker image"
	@echo "  docker-push     Push the Docker image"
	@echo "  deploy     	 Install the Helm Chart"
	@echo "  undeploy     	 Uninstall the Helm Chart"
	@echo "  lint            Run golangci-lint"
	@echo "  fmt             Run go fmt and go vet"
	@echo "  tidy     		 Run go mod tidy"
	@echo "  vendor   		 Run go mod vendor"
	@echo "  check           Run fmt, lint, test, and coverage"
	@echo "  run             Build and run the plugin locally"
