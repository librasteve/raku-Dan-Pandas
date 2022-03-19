#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Pandas;

my \s = $;
#s = Series.new([1, 3, 5, NaN, 6, 8]);
#s = Series.new(data=>[1, 3, 5, NaN, 6, 8]);
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#s = Series.new( [rand xx 5], index => <a b c d e>);
s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
say ~s;
say s.dtype;
say s.index;

