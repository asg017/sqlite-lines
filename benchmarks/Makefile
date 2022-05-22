SHELL=/bin/bash

big-calc.png: ./big-calc/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine=width:800 \
		--width 825 \
		--redefine-file=data:json:./big-calc/results.json \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Aggregate a 5.4GB NDJSON file with 18M objects' \
		'--redefine=footer:sqlite-lines v0.0.0 on a DigitalOcean Droplet, 8GB of RAM' \
		-o $@

count-ndjson.png: ./count-ndjson/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine=width:800 \
		--width 825 \
		--redefine-file=data:json:$< \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Count 321K objects in a 185MB NDJSON file' \
		'--redefine=footer:sqlite-lines v0.0.0 on a DigitalOcean Droplet, 8GB of RAM' \
		-o $@

calc.png: ./calc/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine=width:800 \
		--width 825 \
		--redefine-file=data:json:$< \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Aggregate a 185MB NDJSON file with 321k objects' \
		'--redefine=footer:sqlite-lines v0.0.0 on a DigitalOcean Droplet, 8GB of RAM' \
		-o $@

draw-insert.png: ./draw-insert/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine=width:800 \
		--width 825 \
		--redefine-file=data:json:$< \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Inserting 321k objects from a 185MB NDJSON file into a SQLite database' \
		'--redefine=footer:sqlite-lines v0.0.0 on a DigitalOcean Droplet, 8GB of RAM' \
		-o $@

plain-filter.png: ./plain-filter/results.json
	observable-prerender @asg017/hyperfine-benchmark-viz1 chart  \
		--redefine=width:800 \
		--width 825 \
		--redefine-file=data:json:$< \
		--redefine-file=highlight:json:<(echo '["./sqlite-lines.sh"]') \
		'--redefine=compareTo:./sqlite-lines.sh' \
		'--redefine=title:Count number of sh* words in /usr/share/dict/words' \
		'--redefine=footer:sqlite-lines v0.0.0 on a DigitalOcean Droplet, 8GB of RAM' \
		-o $@

all: ./big-calc.png count-ndjson.png calc.png draw-insert.png plain-filter.png

clean: 
	rm *.png

.PHONY: all clean