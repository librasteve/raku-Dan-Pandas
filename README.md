# raku Dan::Pandas
Dan::Pandas is the first specializer for the raku [Dan](https://github.com/p6steve/raku-Dan) **D**ata **AN**alysis Module.

Dan::Pandas uses the raku [Inline::Python](https://raku.land/cpan:NINE/Inline::Python) module to construct shadow Python objects and to wrap them to maintain the Dan API.
- Dan::Pandas::Series is a specialized Dan::Series
- Dan::Pandas::DataFrame is a specialized Dan::DataFrame

It adapts Dan maintaining **the base set of raku-style** datatype roles, accessors & methods - with a few exceptions as noted below, a Dan::Pandas object can be a drop in replacement for it's Dan equivalent.

A Dockerfile is provided based on the Python [jupyter/scipy-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-scipy-notebook) - ideal for example Dan Jupyter notebooks!

_Contributions via PR are very welcome - please see the backlog Issue, or just email p6steve@furnival.net to share ideas!_

# Installation
- docker run -it p6steve/raku-dan:pandas-2022.02-amd64 -or- :pandas-2022.02.arm64 (see Dockerfile)
- zef install https://github.com/p6steve/raku-Dan-Pandas.git
- cd /usr/share/perl6/site/bin && ./synopsis-dan-pandas.raku

# SYNOPOSIS
The raku Dan [README.md](https://github.com/p6steve/raku-Dan/blob/main/README.md) is a good outline of the Dan API. This synopsis emphasizes the differences, more examples in [bin/synopsis-dan-pandas.raku](https://github.com/p6steve/raku-Dan/blob/main/bin/synopsis-dan-pandas.raku).
```raku
#!/usr/bin/env raku
use lib '../lib';

use Dan;                #<== unlike a standalone Dan script, do NOT use the :ALL selector here
use Dan::Pandas;

### Series ###

## Dan Similarities...

my \s = Series.new( [rand xx 5], index => <a b c d e>);
say ~s;

#`[
a    0.297975
b    0.881274
c    0.868242
d    0.593949
e    0.141334
Name: anon, dtype: float64                   #<== Dan::Pandas::Series has a Python numpy dtype
#]

# Methods
s.dtype;
s.ix;
s.index;
s.elems;
s.map(*+2);
s.splice(1,2,(j=>3));

my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;

# Operators & Accessors
[+] s;  
s >>+>> 2; 
s >>+<< s; 
s[2];
s<c>;

say "---------------------------------------------";
## Dan Differences...

say ~s.reindex(['d','e','f','g','h','i']);   #<== reindex Pandas style, padding NaN
#`[
d    0.593949
e    0.141334
f         NaN
g         NaN
h         NaN
i         NaN
#]
Name: anon, dtype: float64

s.pull;       #explicit pull operation synchronizes raku object attributes to latest Python values (@.dfata, %.index, %.columns)

#The Dan::Pandas .pd method takes a Python method call string and handles it from raku:
s.pd: '.shape';
s.pd: '.flags';
s.pd: '.T';
s.pd: '.to_json("test.json")';
s.pd: '.to_csv("test.csv")';
s.pd: '.iloc[2] = 23';
s.pd: '.iloc[2]';

# 2-arity .pd methods are done like this:
say ~my \quants = Series.new([100, 15, 50, 15, 25]);
say ~my \prices = Series.new([1.1, 4.3, 2.2, 7.41, 2.89]); 

my \costs = quants; 
costs.pd: '.mul', prices; 

# round-trip to/from Dan::Series:
my \u = s.Dan-Series;     #Dan::Series [coerce from Dan::Pandas::Series]
my \v = Series.new( u );  #Dan::Pandas::Series [construct from Dan::Series]

say "---------------------------------------------";
### DataFrames ###

## Dan Similarities...

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];
my \df = DataFrame.new( [[rand xx 4] xx 6], index => dates, columns => <A B C D> );
say ~df;

# Accessors
df[0;0];                   # Data Accessors [row;col]
df[0;0] = 3;               # NOPE! <== unlike Dan, must use .pd method to set values, then optionally .pull
df[0]<A>;                  # Cascading Accessors (mix Positional and Associative)
df[0];                     # 1d Row 0 (DataSlice)
df[*]<A>;                  # 1d Col A (Series)

# Operations
[+] df[*;1];               # 2d Map/Reduce
df >>+>> 2;                # Hyper
df.T;                      # Transpose
df.shape;                  # Shape
df.describe;               # Describe

df.sort: {.[1]};           # Sort by 2nd col (ascending)
df.grep( {.[1] < 0.5} );   # Grep (binary filter) by 2nd column

# Splice
df2.splice( 1, 2, [j => $ds] );         # row-wise splice:
df2.splice( :ax, 1, 2, [K => $se] );    # column-wise splice: axis => 1

# Concat
my \dfa = DataFrame.new( [['a', 1], ['b', 2]], columns => <letter number> ); 
my \dfc = DataFrame.new( [['c', 3, 'cat'], ['d', 4, 'dog']], columns => <animal letter number> ); 

dfa.concat(dfc);
say ~dfa;

#`[
    letter number  animal
0        a      1     NaN
1        b      2     NaN
0⋅1    cat      c     3.0
1⋅1    dog      d     4.0
#]

say "---------------------------------------------";
## Dan Differences...

df.pull;       #explicit pull operation synchronizes raku object attributes to latest Python values (@.dfata, %.index, %.columns)

### .pd Methods ###

#The Dan::Pandas .pd method takes a Python method call string and handles it from raku:
df.pd: '.flags';
df.pd: '.to_json("test.json")';
df.pd: '.to_csv("test.csv")';
df.pd: '.iloc[2] = 23';
df.pd: '.iloc[2]';
say ~df;

#`[
                    A          B          C          D
2022-01-01   0.744346   0.963167   0.548315   0.667035
2022-01-02   0.109722   0.007992   0.999305   0.613870
2022-01-03  23.000000  23.000000  23.000000  23.000000
2022-01-04   0.403802   0.762486   0.220328   0.152730
2022-01-05   0.245156   0.864305   0.577664   0.365762
2022-01-06   0.414237   0.981379   0.571082   0.926982
#]

# 2-arity .pd methods and round trip follow the Series model
```
