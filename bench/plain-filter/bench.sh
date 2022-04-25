#!/bin/bash
hyperfine --warmup 3 './sqlite-lines.sh' './unix.sh'