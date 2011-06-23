#!/usr/local/bin/bash

cd /home/glick/AINews/code
date >> ../logs/log.txt 2>&1
python AINews.py all >> ../logs/log.txt 2>&1
echo "AINewsFinder Finished!" >> ../logs/log.txt 2>&1


