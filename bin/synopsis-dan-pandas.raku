#!/usr/bin/env raku
use lib '../lib';

use Inline::Python;
my $py = Inline::Python.new();
$py.run('print("hello world")');

$py.run('import numpy as np');
$py.run('import pandas as pd');

my $ps = EVAL('pd.Series([1, 3, 5, np.nan, 6, 8])', :lang<Python>);
dd $ps;

my $po = EVAL('print(pd.Series([1, 3, 5, np.nan, 6, 8]))', :lang<Python>);
dd $po;

use Dan;
say ~Series.new([1, 3, 5, NaN, 6, 8]);

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



