SHELL=/bin/bash

draw-calc.png: ./draw-calc/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine-file=data:json:./draw-calc/results.json \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Reading a 185MB NDJSON file with 321k objects and performing a small calculation' \
		'--redefine=footer:Ran on Macbook etc.' \
		-o $@

plain-filter.png: ./plain-filter/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine-file=data:json:./plain-filter/results.json \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Count number of sh* words in /usr/share/dict/words' \
		'--redefine=footer:Ran on Macbook etc.' \
		-o $@

all: draw-calc.png plain-filter.png

clean: 
	rm *.png

.PHONY: all clean