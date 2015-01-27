#!/usr/bin/perl
use strict;

 #pipeline for edit
#system ("./pipeline_metric.pl edit-num dev_2/cz-en/newssyscombtest2010.cz-en.ref.xml dev_2/cz-en/edit conll_config_xml.txt 0 0");
#sleep(60);
#system ("./pipeline_metric.pl edit-num dev_2/de-en/newssyscombtest2010.de-en.ref.xml dev_2/de-en/edit conll_config_xml.txt 0 0");
#sleep(60);
#system ("./pipeline_metric.pl edit-num dev_2/es-en/newssyscombtest2010.es-en.ref.xml dev_2/es-en/edit conll_config_xml.txt 0 0");
#sleep(60);
#system ("./pipeline_metric.pl edit-num dev_2/fr-en/newssyscombtest2010.fr-en.ref.xml dev_2/fr-en/edit conll_config_xml.txt 0 0");
#sleep(60);
 
#pipeline for edit_2
# system ("./pipeline_metric.pl edit-lm dev_2/cz-en/newssyscombtest2010.cz-en.ref.xml dev_2/cz-en/edit_lm conll_config_xml.txt 0 0");
#sleep(60);
# system ("./pipeline_metric.pl edit-lm dev_2/de-en/newssyscombtest2010.de-en.ref.xml dev_2/de-en/edit_lm conll_config_xml.txt 0 0");
# sleep(60);
# system ("./pipeline_metric.pl edit-lm dev_2/es-en/newssyscombtest2010.es-en.ref.xml dev_2/es-en/edit_lm conll_config_xml.txt 0 0");
#sleep(60);
#system ("./pipeline_metric.pl edit-lm dev_2/fr-en/newssyscombtest2010.fr-en.ref.xml dev_2/fr-en/edit_lm conll_config_xml.txt 0 0");
#sleep(60);
 
 #pipeline for match with tine
system ("./pipeline_metric.pl match dev_2/cz-en/newssyscombtest2010.cz-en.ref.xml dev_2/cz-en/match conll_config_xml.txt 0 0");
#system ("./pipeline_metric.pl tine dev_3/cz-en/newssyscombtest2010.cz-en.ref.xml dev_3/cz-en/match conll_config_xml.txt 0 0"); 
sleep(180);
system ("./pipeline_metric.pl match dev_2/de-en/newssyscombtest2010.de-en.ref.xml dev_2/de-en/match conll_config_xml.txt 0 0");
#system ("./pipeline_metric.pl tine dev_3/de-en/newssyscombtest2010.de-en.ref.xml dev_3/de-en/match conll_config_xml.txt 0 0");
 sleep(180);
system ("./pipeline_metric.pl match dev_2/es-en/newssyscombtest2010.es-en.ref.xml dev_2/es-en/match conll_config_xml.txt 0 0");
#system ("./pipeline_metric.pl tine dev_3/es-en/newssyscombtest2010.es-en.ref.xml dev_3/es-en/match conll_config_xml.txt 0 0");
sleep(180);
system ("./pipeline_metric.pl match dev_2/fr-en/newssyscombtest2010.fr-en.ref.xml dev_2/fr-en/match conll_config_xml.txt 0 0");
#system ("./pipeline_metric.pl tine dev_3/fr-en/newssyscombtest2010.fr-en.ref.xml dev_3/fr-en/match conll_config_xml.txt 0 0");
sleep(180);

