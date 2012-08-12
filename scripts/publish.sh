#!/bin/bash

cd /home/aitopicsadmin/NewsFinder/code
date >> ../logs/log.txt 2>&1
python AINews.py publish >> ../logs/log.txt 2>&1
echo "AINewsFinder Finished!" >> ../logs/log.txt 2>&1
