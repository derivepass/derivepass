package: rebuild clean
	./node_modules/.bin/electron-packager --icon=icons/mac.icns . DerivePass

clean:
	rm -rf ./DerivePass-*/

rebuild:
	HOME=~/.electron-gyp node-gyp rebuild --target=1.4.13 --dist-url=https://atom.io/download/electron

.PHONY: package rebuild clean
