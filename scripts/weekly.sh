#!/usr/local/bin/bash

export PYTHONPATH=/home/glick/lib/python

export PATH=/home/glick/bin:/home/glick/bin/git/bin:/home/glick/bin/svm:/usr/local/bin:$PATH

cp /home/glick/html/semiauto_email-blank.html /home/glick/html/semiauto_email.html
rm /home/glick/NewsFinder/output/email_output.txt
cd /home/glick/NewsFinder/code
date >> ../logs/log.txt 2>&1
python AINews.py crawl >> ../logs/log.txt 2>&1
python AINews.py publish >> ../logs/log.txt 2>&1
echo "AINewsFinder Finished!" >> ../logs/log.txt 2>&1


