#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Pandas;

#my $ser = Series.new([1, 3, 5, NaN, 6, 8]);
#my $ser = Series.new(data=>[1, 3, 5, NaN, 6, 8]);
#my $ser = Series.new(data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#my $ser = Series.new( [rand xx 5], index => <a b c d e>);
my $ser = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
say ~$ser;
say $ser.dtype;



