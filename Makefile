.PHONY: test package submission

test:
	lua tests/run.lua
	lua tests/native.lua
	luac -p main.lua xbb/*.lua tests/*.lua

package: test
	rm -rf -- dist/XBB
	mkdir -p dist/XBB/xbb
	cp main.lua plugin.json dist/XBB/
	cp xbb/*.lua dist/XBB/xbb/

submission: package
	cd dist/XBB && python3 -m zipfile -c ../XBB.zip main.lua plugin.json xbb
