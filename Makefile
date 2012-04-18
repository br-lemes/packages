all: build.sh

build.sh: build/*
	@cat $+ > $@
	@echo 'main $$1 $$2' >> $@
	@chmod +x $@

package: build.sh
	@./build.sh package

install: build.sh
	@./build.sh install

uninstall: build.sh
	@./build.sh uninstall

clean:
	@./build.sh clean
	@rm build.sh
