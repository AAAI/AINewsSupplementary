#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Data::Dumper;
use DBI;

my $host = "localhost";
my $database = "ainews";
my $user = "root";
my $pw = "lambda%0";
my $table_corpus = "cat_corpus";
my $table_categories = "cat_corpus_cats";

my $mysql = DBI->connect("DBI:mysql:database=$database;host=$host", $user, $pw);

my $extractor = '/home/josh/AINews/extractors/goose/run.sh';
my $savedir = '/home/josh/AINews/corpus/extracted';

my $catprefix = "http://www.aaai.org/AITopics/pmwiki/pmwiki.php/AITopics/";

my @valid_cats = ("AIOverview","Agents", "Applications",
        "CognitiveScience","Education","Ethics", "Games", "History",
        "Interfaces","MachineLearning","NaturalLanguage","Philosophy",
        "Reasoning","Representation", "Robots","ScienceFiction",
        "Speech", "Systems","Vision");

my $mech = WWW::Mechanize->new(autocheck => 0);
$mech->timeout(10);
$mech->agent_alias('Windows IE 6');

my @urls = ();
foreach my $prefix (("B", "C", "D", "E", "F", "G", "H", "I", "J"))
{
    for(my $i = 1; $i <= 12; $i++)
    {
        push(@urls, "http://www.aaai.org/AITopics/html/archv$prefix$i.html");
    }
}

my $article_count = 0;
my $article_success = 0;
my $wayback_count = 0;
my $wayback_success = 0;

foreach my $url (@urls)
{
    $mech->get($url);
    if(!$mech->success()) { next; }

    print "Reading $url\n\n";

    my $content = $mech->content();

    my @links = $mech->links();

    my $parser = HTML::TreeBuilder->new_from_content($content);

    my $href;
    my $active_url = "";
    my @categories = ();
    my %cats_seen = ();

    foreach my $node ($parser->guts()->descendents())
    {
        if($node->tag eq 'p')
        {
            foreach my $subnode ($node->descendents())
            {
                if($subnode->tag eq 'a' && defined($subnode->attr('href'))
                        && $subnode->attr('href') =~ m/^http:/)
                {
                    $href = $subnode->attr('href');
                    if(!($href =~ m/$catprefix/) && !($href =~ m/aaai\.org/))
                    {
                        # Have a new URL; try to save the prior one
                        if($active_url ne "" && !(@categories))
                        {
                            print "No categories.\n\n";
                            $active_url = "";
                        }
                        elsif($active_url ne "")
                        {
                            my $title = "";
                            $mech->get($active_url);
                            if($mech->success() && defined($mech->title()))
                            {
                                $title = $mech->title();
                            }

                            my $article = `$extractor \"$active_url\" 2>/dev/null`;
                            $article =~ s/&.*?;//g;

                            if(!($article =~ m/\S/) ||
                                ($article =~ m/^Make sure you pass in a valid URL/))
                            {
                                print "Empty article\n\n";
                                $active_url = "";
                                next;
                            }

                            print "\nCategories: ";
                            foreach my $cat (@categories) {
                                print "$cat ";
                            }
                            print "\n\n";

                            $article_success++;
                            if($active_url =~ m!^http://web\.archive\.org!)
                            {
                                $wayback_success++;
                            }

                            $mysql->do("INSERT INTO $table_corpus (url, title, content) " .
                                    "VALUES(?, ?, ?)", undef, $active_url, $title, $article);

                            my $urlid = $mysql->{'mysql_insertid'};
                            foreach my $cat (@categories) {
                                $mysql->do("INSERT INTO $table_categories VALUES(?, ?)",
                                        undef, $urlid, $cat);
                            }

                            print "Article success: $article_success/$article_count " .
                                "(wayback: $wayback_success/$wayback_count)\n\n\n";
                        }

                        @categories = ();
                        %cats_seen = ();

                        print "Trying $href\n";
                        $article_count++;

                        $mech->get($href);
                        if(!$mech->success())
                        {
                            print "(FAILED: ".$mech->status().")\n\n";

                            my $wayback_url = "http://wayback.archive.org/web/*/$href";
                            print "Wayback url: $wayback_url\n\n";
                            $mech->get($wayback_url);
                            if(!$mech->success())
                            {
                                print "Wayback reply: ".$mech->status()."\n\n";
                                $active_url = "";
                                next;
                            }

                            my $wayback_parser = HTML::TreeBuilder->new_from_content($mech->content());


                            foreach my $wayback_node ($wayback_parser->guts()->descendents())
                            {
                                if($wayback_node->tag eq 'a' && defined($wayback_node->attr('href'))
                                    && $wayback_node->attr('href') =~
                                        m!^http://web\.archive\.org/web/\d+/$href$!)
                                {
                                    $href = $wayback_node->attr('href');
                                    # don't "last" here, get the most recent link
                                }
                            }
                            $wayback_parser->delete;

                            $mech->get($href);
                            if(!$mech->success())
                            {
                                $active_url = "";
                                print "Wayback failed with $href\n\n";
                                next;
                            }
                            print "Wayback machine worked.\n";
                            $wayback_count++;
                        }
                        $active_url = $href;
                    }
                    elsif($href =~ m/$catprefix/)
                    {
                        my ($cat) = ($href =~ m/^$catprefix(.*)$/);
                        $cat =~ s/#.*$//;
                        if(grep {/^$cat$/} @valid_cats)
                        {
                            push(@categories, $cat) unless $cats_seen{$cat}++;
                        }
                    }
                }
            }
        }
    }

    $parser->delete;
}

