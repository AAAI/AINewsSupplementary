#!/bin/bash

cp /var/www/wiki/html/semiauto_email-blank.html /var/www/wiki/html/semiauto_email.html
rm /home/aitopicsadmin/NewsFinder/output/email_output.txt
cd /home/aitopicsadmin/NewsFinder/code
date >> ../logs/log.txt 2>&1
python AINews.py crawl >> ../logs/log.txt 2>&1
python AINews.py prepare >> ../logs/log.txt 2>&1
echo "AINewsFinder Finished!" >> ../logs/log.txt 2>&1
