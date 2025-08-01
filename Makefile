bundle:
	@bundle install
.PHONY: bundle

publish: bundle
	@bundle exec pod trunk push TPTweak.podspec --allow-warnings
.PHONY: publish
