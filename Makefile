.PHONY: test

MODULE_DIR = ./node_modules
BIN_DIR = $(MODULE_DIR)/.bin
MOCHA_BIN = $(BIN_DIR)/mocha
TEST_UNIT_DIR = ./test
MOCHA_REPORTER = spec

install:
	npm install

clean:
	rm -rf ./node_modules

test: test-unit

test-unit: $(MOCHA_BIN)
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

test-watch:
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --watch --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

cov:
	$(MOCHA_BIN) --compilers coffee:coffee-script/register --colors -R mocha-spec-cov-alt --require blanket $(TEST_UNIT_DIR)

coveralls:
	NODE_ENV=test $(MOCHA_BIN) --compilers coffee:coffee-script/register -R mocha-lcov-reporter --require blanket $(TEST_UNIT_DIR) | $(BIN_DIR)/coveralls

cov-html:
	$(MOCHA_BIN) --compilers coffee:coffee-script/register -R html-cov --require blanket $(TEST_UNIT_DIR) > ./cov.html
