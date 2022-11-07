# =================================================== #
# HELPERS                                             #
# =================================================== #

PCKG=sfs
REV=1
VER=1.0.0
ARCH=amd64
DESCR=""

PCKGNAME="$(PCKG)_$(VER)-$(REV)_$(ARCH)"

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

## pack: create deb package
.PHONY: pack
pack:
# create directory for executable file
# copy executable file
	mkdir -p "$(PCKGNAME)/usr/local/bin" && cp SFS "$(PCKGNAME)/usr/local/bin/"
# create man file
	mkdir -p "$(PCKGNAME)/usr/share/man/man8"
	cp doc/sfs.8 "$(PCKGNAME)/usr/share/man/man8/" && gzip "$(PCKGNAME)/usr/share/man/man8/sfs.8"
# create systemd unit
	mkdir -p "$(PCKGNAME)/usr/lib/systemd/system"
	cp sfs.service "$(PCKGNAME)/usr/lib/systemd/system/"
# create DEBIAN directory
# copy installation and remove scripts
# create information file DEBIAN/control
	mkdir -p "$(PCKGNAME)/DEBIAN" && cp install/* "$(PCKGNAME)/DEBIAN/"
	touch "$(PCKGNAME)/DEBIAN/control"
	echo "Package: $(PCKG)"      >> "$(PCKGNAME)/DEBIAN/control"
	echo "Version: $(VER)"       >> "$(PCKGNAME)/DEBIAN/control"
	echo "Architecture: $(ARCH)" >> "$(PCKGNAME)/DEBIAN/control"
	echo "Maintainer: Aleksey Shaforostov <AIgShaforostov@rasu.ru>" >> "$(PCKGNAME)/DEBIAN/control"
	echo "Description: $(DESCR)" >> "$(PCKGNAME)/DEBIAN/control"
# build package
	dpkg-deb --build --root-owner-group $(PCKGNAME)


# =================================================== #
# CLEAN                                               #
# =================================================== #

## clean: remove temporary files
.PHONY: clean
clean:
	rm -r $(PCKG)_$(VER)-$(REV)_$(ARCH)
	go clean
