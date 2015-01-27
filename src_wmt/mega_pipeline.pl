#!/usr/bin/perl
use strict;


  #pipeline for edit
#system ("./pipeline_metric.pl edit-num test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/cz-en/edit conll_config.txt 0 0");
#sleep(240);
#system ("./pipeline_metric.pl edit-num test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/de-en/edit conll_config.txt 0 0");
#sleep(240);
#system ("./pipeline_metric.pl edit-num test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/es-en/edit conll_config.txt 0 0");
#sleep(240);
#system ("./pipeline_metric.pl edit-num test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/fr-en/edit conll_config.txt 0 0");
#sleep(240);


#pipeline for edit_2
#system ("./pipeline_metric.pl edit-lm test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/cz-en/edit_2 conll_config.txt 0 0");
#sleep(340);
#system ("./pipeline_metric.pl edit-lm test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/de-en/edit_2 conll_config.txt 0 0");
#sleep(340);
#system ("./pipeline_metric.pl edit-lm test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/es-en/edit_2 conll_config.txt 0 0");
#sleep(340);
#system ("./pipeline_metric.pl edit-lm test/ax_bx/newssyscombtest2011-test_3/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_3/fr-en/edit_2 conll_config.txt 0 0");
#sleep(340);


#pipeline for match
system ("./pipeline_metric.pl match test/ax_bx/test_f/newssyscombtest2011-ref.en.sgm test/ax_bx/test_f/cz-en conll_config.txt 0 0");
sleep(180);
system ("./pipeline_metric.pl match test/ax_bx/test_f/newssyscombtest2011-ref.en.sgm test/ax_bx/test_f/de-en conll_config.txt 0 0");
sleep(180);
system ("./pipeline_metric.pl match test/ax_bx/test_f/newssyscombtest2011-ref.en.sgm test/ax_bx/test_f/es-en conll_config.txt 0 0");
sleep(180);
system ("./pipeline_metric.pl match test/ax_bx/test_f/newssyscombtest2011-ref.en.sgm test/ax_bx/test_f/fr-en conll_config.txt 0 0");
sleep(180);
