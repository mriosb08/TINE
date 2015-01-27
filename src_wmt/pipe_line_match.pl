#!/usr/bin/perl

use strict;
#pipeline for match
system ("./pipeline_metric.pl match test/ax_bx/newssyscombtest2011-test_2/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_2/cz-en/match conll_config.txt 0 1");
sleep(740);
system ("./pipeline_metric.pl match test/ax_bx/newssyscombtest2011-test_2/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_2/de-en/match conll_config.txt 0 1");
sleep(740);
system ("./pipeline_metric.pl match test/ax_bx/newssyscombtest2011-test_2/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_2/es-en/match conll_config.txt 0 1");
sleep(740);
system ("./pipeline_metric.pl match test/ax_bx/newssyscombtest2011-test_2/newssyscombtest2011-ref.en.sgm test/ax_bx/newssyscombtest2011-test_2/fr-en/match conll_config.txt 0 1");
sleep(740);
