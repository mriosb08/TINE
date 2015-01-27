#!/usr/bin/perl

use strict;
 #pipeline for match
system ("./pipeline_metric_training.pl edit-num training/cz-en/newssyscombtest2010.cz-en.ref.xml training/cz-en/edit conll_config_xml.txt");
sleep(220);
system ("./pipeline_metric_training.pl edit-num training/de-en/newssyscombtest2010.de-en.ref.xml training/de-en/edit conll_config_xml.txt");
sleep(220);
system ("./pipeline_metric_training.pl edit-num training/es-en/newssyscombtest2010.es-en.ref.xml training/es-en/edit conll_config_xml.txt");
sleep(220);
system ("./pipeline_metric_training.pl edit-num training/fr-en/newssyscombtest2010.fr-en.ref.xml training/fr-en/edit conll_config_xml.txt");
sleep(220);
