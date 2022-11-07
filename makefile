# =================================================== #
# HELPERS                                             #
# =================================================== #

## help: print this help mesage
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

# =================================================== #
# QUALITY CONTROL                                     #
# =================================================== #

## tidy: format code and tidy modfile
.PHONY: tidy
tidy:
	go fmt ./...
	go mod tidy -v

## audit: run quality control checks
.PHONY: audit
audit:
	go vet ./...
	go test -race -vet=off ./...
	go mod verify

# =================================================== #
# BUILD                                               #
# =================================================== #

## build: build the application
##     *: you should install UPX packer for target build
.PHONY: build
build:
	go mod verify
	go build -ldflags "-s -w" -o SFS ./...
	upx --best --lzma SFS
	GOOS=windows go build -ldflags "-s -w" -o SFS.exe ./...

## run: run the application
.PHONY: run
run: tidy build
	./SFS.EXE start --port 9999 --dir .
