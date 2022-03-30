#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Pandas;

my \s = $;
#my $index = {:a(0), :b(1), :c(2), :d(3), :e(4), :f(5)};
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], :$index, name => 'john' );
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#s = Series.new(data => [1, 3, 5, NaN, 6, 8]);
#s = Series.new([1, 3, 5, 6, 8]);
#s = Series.new([1, 3, 5, NaN, 6, 8]);
#s = Series.new( [rand xx 5], index => <a b c d e>);
s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs

#say s.dtype;
#say s.ix;
#say s.index;
#say ~s.reindex(['d','e','f','g','h','i']);
#say s.elems;
say s.pull;
say ~s;

#say s.map(*+2);
#say [+] s; 
#say s >>+>> 2; 
#say s >>+<< s; 

say s[2];
say s<c>;

say ~s;

#`[ pd methods
s.pd: '.shape';
s.pd: '.flags';
s.pd: '.T';
s.pd: '.to_json("test.json")';
s.pd: '.to_csv("test.csv")';
s.pd: '.iloc[2] = 23';
s.pd: '.iloc[2]';
#]

s.splice(1,2,(j=>3)); 
s.fillna;

say ~s;
dd s.^methods;

my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;

say ~s;

