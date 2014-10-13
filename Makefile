PACKAGE := github.com/hamfist/artifacts-service
SUBPACKAGES := \
	$(PACKAGE)/artifact \
	$(PACKAGE)/auth \
	$(PACKAGE)/metadata \
	$(PACKAGE)/server \
	$(PACKAGE)/store

VERSION_VAR := main.VersionString
VERSION_VALUE := $(shell git describe --always --dirty --tags)
REV_VAR := main.RevisionString
REV_VALUE := $(shell git rev-parse --sq HEAD)
GENERATED_VAR := main.GeneratedString
GENERATED_VALUE := $(shell date -u +'%Y-%m-%dT%H:%M:%S%z')

FIND ?= find
GO ?= go
DEPPY ?= deppy
GOPATH := $(shell echo $${GOPATH%%:*})
GOBUILD_LDFLAGS := -ldflags "\
	-X $(VERSION_VAR) $(VERSION_VALUE) \
	-X $(REV_VAR) $(REV_VALUE) \
	-X $(GENERATED_VAR) $(GENERATED_VALUE) \
"
GOBUILD_FLAGS ?= -x

DATABASE_URL ?= 'postgres://artifacts:dogs@localhost:5432/artifacts?sslmode=disable'
PORT ?= 9839

export DATABASE_URL
export PORT

COVERPROFILES := \
	artifact-coverage.coverprofile \
	auth-coverage.coverprofile \
	metadata-coverage.coverprofile \
	server-coverage.coverprofile \
	store-coverage.coverprofile

%-coverage.coverprofile:
	$(GO) test -covermode=count -coverprofile=$@ \
		$(GOBUILD_LDFLAGS) $(PACKAGE)/$(subst -coverage.coverprofile,,$@)

.PHONY: all
all: clean deps test lintall

.PHONY: test
test: build fmtpolice test-deps test-race coverage.html

.PHONY: test-deps
test-deps:
	$(GO) test -i $(GOBUILD_LDFLAGS) $(PACKAGE) $(SUBPACKAGES)

.PHONY: test-race
test-race:
	$(GO) test -race $(GOBUILD_LDFLAGS) $(PACKAGE) $(SUBPACKAGES)

coverage.html: coverage.coverprofile
	$(GO) tool cover -html=$^ -o $@

coverage.coverprofile: $(COVERPROFILES)
	./bin/fold-coverprofiles $^ > $@
	$(GO) tool cover -func=$@

.PHONY: build
build:
	$(GO) install $(GOBUILD_FLAGS) $(GOBUILD_LDFLAGS) $(PACKAGE)

.PHONY: deps
deps:
	$(GO) get $(GOBUILD_FLAGS) $(GOBUILD_LDFLAGS) $(PACKAGE)

.PHONY: clean
clean:
	./bin/clean

.PHONY: save
save:
	$(DEPPY) save

.PHONY: fmtpolice
fmtpolice:
	./bin/fmtpolice

.PHONY: lintall
lintall:
	./bin/lintall
