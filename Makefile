# go run -ldflags "-X mikrotik-exporter/cmd.version=6.6.7-BETA -X mikrotik-exporter/cmd.shortSha=`git rev-parse HEAD`" main.go version

VERSION=`cat VERSION`
SHORTSHA=`git rev-parse --short HEAD`

LDFLAGS=-X main.appVersion=$(VERSION)
LDFLAGS+=-X main.shortSha=$(SHORTSHA)

build:
	go build -ldflags "$(LDFLAGS)" .

utils:
	go install github.com/mitchellh/gox@v1.0.1
	go install github.com/tcnksm/ghr@v0.16.0
	
deploy: utils
	CGO_ENABLED=0 gox -os="linux freebsd netbsd" -arch="amd64 arm arm64 386" -parallel=4 -ldflags "$(LDFLAGS)" -output "dist/mikrotik-exporter_{{.OS}}_{{.Arch}}"
	@ghr -t $(GITHUB_TOKEN) -u $(CIRCLE_PROJECT_USERNAME) -r $(CIRCLE_PROJECT_REPONAME) -c "${CIRCLE_SHA1}" $(SHORT_GIT_HASH) dist/

dockerhub: deploy
	set -x
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	docker build -t $(DOCKER_USER)/$(CIRCLE_PROJECT_REPONAME):$(SHORT_GIT_HASH) .
	docker push $(DOCKER_USER)/$(CIRCLE_PROJECT_REPONAME):$(SHORT_GIT_HASH)
	docker build -f Dockerfile.arm64 -t $(DOCKER_USER)/$(CIRCLE_PROJECT_REPONAME)-linux-arm64:$(SHORT_GIT_HASH) .
	docker push $(DOCKER_USER)/$(CIRCLE_PROJECT_REPONAME)-linux-arm64:$(SHORT_GIT_HASH)
