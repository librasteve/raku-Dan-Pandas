#!/usr/bin/env raku
use lib '../lib';

use Inline::Python;
my $py = Inline::Python.new();
$py.run('print("hello world")');

$py.run('import numpy as np');
$py.run('import pandas as pd');
say EVAL('pd.Series([1, 3, 5, np.nan, 6, 8])', :lang<Python>);

#`[
use string:from<Python>;
my $t = string::capwords('foo bar');
say $t;

dd string::;

use numpy:from<Python>;
use pandas:from<Python>;

dd pandas::;    ## <== only shows symbols from base pandas lib (not Series!)

my $s = pandas::Series([1, 3, 5, 6, 8]);
say $s;
#]

#use matplotlib::pyplot:from<Python>;


