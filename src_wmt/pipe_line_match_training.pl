#!/usr/bin/perl

use strict;
#pipeline for match
system ("./pipeline_metric_training.pl match training/cz-en/newssyscombtest2010.cz-en.ref.xml training/cz-en/match conll_config_xml.txt");
sleep(540);
system ("./pipeline_metric_training.pl match training/fr-en/newssyscombtest2010.fr-en.ref.xml training/fr-en/match conll_config_xml.txt");
sleep(540);
system ("./pipeline_metric_training.pl match training/de-en/newssyscombtest2010.de-en.ref.xml training/de-en/match conll_config_xml.txt");
sleep(540);
system ("./pipeline_metric_training.pl match training/es-en/newssyscombtest2010.es-en.ref.xml training/es-en/match conll_config_xml.txt");
