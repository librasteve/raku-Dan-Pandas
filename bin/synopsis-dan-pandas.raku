#!/usr/bin/env raku
use MONKEY-SEE-NO-EVAL;

use lib '../lib';
use Inline::Python;

#[[[
use Dan;
use Dan::Pandas;

my $ser = Series.new([1, 3, 5, NaN, 6, 8]);

my $pdf = Dan::Pandas::DataFrame.new([$ser]);
say ~$pdf;
#]]]

#`[[[
use Dan;
use Dan::Pandas;

my $ser = Series.new([1, 3, 5, NaN, 6, 8]) does Dan::Pandas;

my $pdf = DataFrame.new([$ser]) does Dan::Pandas;
say ~$pdf;
#]]]

die;

#`[[[
my $py = Inline::Python.new();
$py.run('print("hello world")');

$py.run('import numpy as np');
$py.run('import pandas as pd');

my $ps = EVAL('pd.Series([1, 3, 5, np.nan, 6, 8])', :lang<Python>);
dd $ps;

my $ix = EVAL('pd.Series([1, 3, 5, np.nan, 6, 8]).index', :lang<Python>);
dd $ix;

my $at = EVAL('pd.Series([1, 3, 5, np.nan, 6, 8]).at[2]', :lang<Python>);
say $at;

my $dt = EVAL('pd.Series([1, 3, 5, np.nan, 6, 8]).dtype.name', :lang<Python>);
say $dt;

my Array $data = $[1e0, 3e0, 5e0, NaN, 6e0, 8e0];
my Array $index = $['a','b','c','d','e','f'];

my $one = 1;
#my $str = "pd.Series([$one, 3, 5, np.nan, 6, 8])";
my $str = "pd.Series([$one, 3, 5, np.nan, 6, 8]).dtype.name";
my $xs = EVAL($str, :lang<Python>);
dd $xs;

#`[
#my $s = pandas::Series($ps);
#my $s = pandas::Series($ps,$ix);
#my $s = pandas::Series( data => $ps, index => $ix );
#my $s = pandas::Series( data => $[1e0,2e0,3e0], index => $['a', 'b', 'c'] );
#my $s = pandas::Series( data => [1e0,2e0,3e0], index => <a b c> );
#my $s = pandas::Series( $[1e0,2e0,3e0], $[0,1,2] );
#my $s = pandas::Series( $[1e0,2e0,3e0], $<a b c> );


use string:from<Python>;
my $t = string::capwords('foo bar');
say $t;

dd string::;

use numpy:from<Python>;
use pandas:from<Python>;

#dd pandas::;    ## <== only shows symbols from base pandas lib (not Series!)

my Array $ps = $[1e0, 3e0, 5e0, NaN, 6e0, 8e0];
#my Array $ps = $[1, 3, 5, 0, 6, 8];  # will not work with Int
#my Array $ix = $[0, 1, 2, 3, 4, 5];
my Array $ix = $['a','b','c','d','e','f'];

#my $s = pandas::Series($ps);
#my $s = pandas::Series($ps,$ix);
#my $s = pandas::Series( data => $ps, index => $ix );
#my $s = pandas::Series( data => $[1e0,2e0,3e0], index => $['a', 'b', 'c'] );
#my $s = pandas::Series( data => [1e0,2e0,3e0], index => <a b c> );
#my $s = pandas::Series( $[1e0,2e0,3e0], $[0,1,2] );
my $s = pandas::Series( $[1e0,2e0,3e0], $<a b c> );
dd $s;
#]

#quite liking the Inline::Python object syntax ... BUT will use the EVAL because it works with ootb IP
# and I can see how to make calls on objects and do a bunch of prep before returning

#]]]
