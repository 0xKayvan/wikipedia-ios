.PHONY=build

XCODE_VERSION = "$(shell xcodebuild -version 2>/dev/null)"

help: ##Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

lint: ##Lint the native code, requires uncrustify
lint:
	@scripts/uncrustify_all.sh

test: ##Run unit tests through fastlane
	@bundle exec fastlane test

submodules: ##Install or update submodules
	git submodule update --init --recursive

check-deps: ##Make sure system prerequisites are installed
check-deps: xcode-cltools-check exec-check node-check

#!!!!!
#!!!!! Travis
#!!!!!

travis-get-deps: ##Install dependencies for building on Travis
travis-get-deps: xcode-cltools-check submodules
	@brew update; \
	brew install uncrustify || brew upgrade uncrustify; \
	brew install xctool || brew upgrade xctool; \
	bundle install --without dev; \
	git status

#!!!!!
#!!!!! Xcode dependencies
#!!!!!

# Required so we (and other tools) can use command line tools, e.g. xcodebuild.
xcode-cltools-check: ##Make sure proper Xcode & command line tools are installed
	@case $(XCODE_VERSION) in \
		"Xcode 6"*) echo "Xcode 6 or higher is installed!" ;; \
		*) echo "Missing Xcode 6 or higher."; exit 1;; \
	esac; \
	if ! xcode-select -p > /dev/null ; then \
		echo "Xcode command line tools are missing! Please run xcode-select --install or download them from Xcode's 'Downloads' tab in preferences."; \
		exit 1; \
	else \
		echo "Xcode command line tools are installed!"; \
	fi

get-xcode-cltools: ##Install Xcode command-line tools
	xcode-select --install

#!!!!!
#!!!!! Executable dependencies
#!!!!!

get-homebrew: ##Install Homebrew using the bootstrapping script from http://brew.sh
	@if [[ $$(brew -v 2>/dev/null) =~ "Homebrew" ]]; then \
		echo "Homebrew already installed!"; \
	else \
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; \
	fi

brew-check: ##Check that Homebrew is installed
	@if [[ $$(brew -v 2>/dev/null) =~ "Homebrew" ]]; then \
		echo "Homebrew is installed!"; \
	else \
		echo "Please setup Homebrew by running `make get-homebrew` or following instructions on http://brew.sh/"; \
		exit 1; \
	fi

# Append additional dependencies as quoted strings (i.e. BREW_FORMULAE = "f1" "f2" ...)
BREW_FORMULAE = "uncrustify" "imagemagick" "gs" "xctool"

brew-install: ##Install executable dependencies via Homebrew
brew-install: brew-check
	@brew install $(BREW_FORMULAE); brew upgrade ${BREW_FORMULAE)

# Append additional dependencies as quoted strings (i.e. EXEC_DEPS = "dep1" "dep2" ...)
EXEC_DEPS = "uncrustify" "convert" "gs" "xctool"

# Note: checking for specific executables instead of formula, since Homebrew
# is just one of many ways to install them
exec-check:  ##Check that executable dependencies are installed
	@for dep in $(EXEC_DEPS); do \
		if [[ -x $$(which $${dep}) ]]; then \
			echo "$${dep} is installed!"; \
		else \
			echo "Missing executable $${dep}, please make sure it's installed on your PATH (e.g. via Homebrew)."; \
			exit 1; \
		fi \
	done

#!!!!!
#!!!!! Web dependency management
#!!!!!

web: ##Make web assets
web: css grunt

CSS_ORIGIN = http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&lang=en&only=styles&skin=vector&modules=
WEB_ASSETS_DIR = "Wikipedia/assets"

define get_css_module
curl -s -L -o
endef

css: ##Download latest stylesheets
	@echo "Downloading CSS assets..."; \
	mkdir -p $(WEB_ASSETS_DIR); \
	cd $(WEB_ASSETS_DIR); \
	$(get_css_module) 'styles.css' "$(CSS_ORIGIN)mobile.app.pagestyles.ios" > /dev/null; \
	$(get_css_module) 'abusefilter.css' "$(CSS_ORIGIN)mobile.app.pagestyles.ios" > /dev/null; \
	$(get_css_module) 'preview.css' "$(CSS_ORIGIN)mobile.app.preview" > /dev/null

NODE_VERSION = "$(shell node -v 2>/dev/null)"
NPM_VERSION = "$(shell npm -version 2>/dev/null)"

grunt: ##Run grunt
grunt: npm
	@cd www && grunt && cd ..

npm: ##Install Javascript dependencies
npm: node-check
	@cd www && npm install && cd ..

get-node: ##Install node via Homebrew
	brew install node

node-check: ##Make sure node is installed
	@if [[ $(NODE_VERSION) > "v0.10" && $(NPM_VERSION) > "1.4" ]]; then \
		echo "node and npm are installed and up to date!" ; \
	else \
	echo "node v0.10 or higher and npm 1.4 or higher are not installed. You can use homebrew to install (brew install node) or upgrade if out of date (brew upgrade node)" ; \
		exit 1; \
	fi

#!!!!!
#!!!!! Native dependency management
#!!!!!

RUBY_VERSION = "$(shell ruby -v 2>/dev/null)"
BUNDLER = "$(shell which bundle 2/dev/null)"

pod: ##Install native dependencies via CocoaPods
pod: bundle-install
	@$(BUNDLER) exec pod install

#!!!!!
#!!!!! Ruby dependency management
#!!!!!

RUBY_VERSION = "$(shell ruby -v 2>/dev/null)"

bundle-install: ##Install all gems using Bundler
bundle-install: bundler-check
	@bundle install

bundler-check: ##Make sure Bundler is installed
bundler-check: ruby-check
	@if ! which -s bundle; then \
		echo "Missing the Bundler Ruby gem." ; \
		exit 1 ; \
	else \
		echo "Bundler is installed!" ; \
	fi

get-bundler: ##Install Bundler, requires Ruby installed outside /usr/bin
get-bundler: get-ruby
	gem install bundler

ruby-check: ##Make sure Ruby is installed
	@if [[ $(RUBY_VERSION) == "" ]]; then \
		echo "Ruby is missing!" ; \
		exit 1 ; \
	else \
		echo "Ruby is installed!" ; \
	fi

get-ruby: ##Install Ruby via Homebrew (to remove need for sudo)
		brew install ruby


#!!!!!
#!!!!! Misc
#!!!!!

bootstrap: ##Only recommended if starting from scratch! Attempts to install all dependencies (Xcode command-line tools Homebrew, Ruby, Node, Bundler, etc...)
	bootstrap: get-xcode-cltools get-homebrew get-node get-bundler brew-install bundle-install
