#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Pandas;

#`[[
my \s = $;
#my $index = {:a(0), :b(1), :c(2), :d(3), :e(4), :f(5)};
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], :$index, name => 'john' );
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#s = Series.new(data => [1, 3, 5, NaN, 6, 8]);
#s = Series.new([1, 3, 5, 6, 8]);
#s = Series.new([1, 3, 5, NaN, 6, 8]);
#s = Series.new( [rand xx 5], index => <a b c d e>);
s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
say ~s;

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

s.splice(1,2,(j=>3)); 
s.fillna;

my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;

#`[ pd methods
s.pd: '.shape';
s.pd: '.flags';
s.pd: '.T';
s.pd: '.to_json("test.json")';
s.pd: '.to_csv("test.csv")';
s.pd: '.iloc[2] = 23';
s.pd: '.iloc[2]';
say ~s;
#]

#`[ 2-arity pd methods
say ~my \quants = Series.new([100, 15, 50, 15, 25]);
say ~my \prices = Series.new([1.1, 4.3, 2.2, 7.41, 2.89]);
#say ~my \costs  = Series.new( quants >>*<< prices );

my \costs = quants;
costs.pd: '.mul', prices;
#]

my \u = s.Dan-Series;
say u.^name;
say ~u;

my \v = Series.new( u );
say v.^name;
say ~v;
#]]

say "=============================================";

### DataFrames ###

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];
my \df = DataFrame.new( [[rand xx 4] xx 6], index => dates, columns => <A B C D> );
#my \df = DataFrame.new( [[rand xx 4] xx 6], columns => <A B C D> );
#my \df = DataFrame.new( [[rand xx 4] xx 6] );
say ~df;

say "---------------------------------------------";

# Data Accessors [row;col]
say df[0;0];
say df[0;0];
df[0;0] = 3;                # set value (not sure why this works, must manual push

# Smart Accessors (mix Positional and Associative)
say df[0][0];
say df[0]<A>;
say df{"2022-01-03"}[1];

# Object Accessors & Slices (see note 1)
say ~df[0];                 # 1d Row 0 (DataSlice)
say ~df[*]<A>;              # 1d Col A (Series)
say ~df[0..*-2][1..*-1];    # 2d DataFrame
#`[
say ~df{dates[0..1]}^;      # the ^ postfix converts an Array of DataSlices into a new DataFrame

say "---------------------------------------------";
#]


