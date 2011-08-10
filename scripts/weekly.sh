#!/usr/local/bin/bash

export PYTHONPATH=/home/glick/lib/python

export PATH=/home/glick/bin:/home/glick/bin/git/bin:/home/glick/bin/svm:/usr/local/bin:$PATH

cd /home/glick/NewsFinder/code
date >> ../logs/log.txt 2>&1
python AINews.py crawl >> ../logs/log.txt 2>&1
python AINews.py publish >> ../logs/log.txt 2>&1
echo "AINewsFinder Finished!" >> ../logs/log.txt 2>&1


