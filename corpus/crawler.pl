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

my $mech = WWW::Mechanize->new(autocheck => 0);
$mech->timeout(10);
$mech->agent_alias('Windows IE 6');

$mech->get("http://www.aaai.org/AITopics/html/archvC5.html");

my $content = $mech->content();

my @links = $mech->links();

my $parser = HTML::TreeBuilder->new_from_content($content);

my $extractor = '/home/josh/Documents/goose/run.sh';
my $savedir = '/home/josh/AINews/corpus/extracted';

my $catprefix = "http://www.aaai.org/AITopics/pmwiki/pmwiki.php/AITopics/";

my @valid_cats = ("AIOverview","Agents", "Applications",
        "CognitiveScience","Education","Ethics", "Games", "History",
        "Interfaces","MachineLearning","NaturalLanguage","Philosophy",
        "Reasoning","Representation", "Robots","ScienceFiction",
        "Speech", "Systems","Vision");

my $active_url;
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
                my $href = $subnode->attr('href');
                if(!($href =~ m/$catprefix/) && !($href =~ m/aaai\.org/))
                {
                    $mech->get($href);
                    if(!$mech->success()) { next; }

                    if(defined($active_url))
                    {
                        print "URL: $active_url\n";
                        print "Categories: ";
                        foreach my $cat (@categories) {
                            print "$cat ";
                        }
                        print "\n\n";

                        my $article = `$extractor \"$active_url\" 2>/dev/null`;
                        $article =~ s/&.*?;//g;

                        $mysql->do("INSERT INTO $table_corpus (url, content) VALUES(?, ?)",
                                undef, $active_url, $article);

                        my $urlid = $mysql->{'mysql_insertid'};
                        foreach my $cat (@categories) {
                            $mysql->do("INSERT INTO $table_categories VALUES(?, ?)",
                                    undef, $urlid, $cat);
                        }
                    }

                    $active_url = $href;

                    @categories = ();
                    %cats_seen = ();
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

