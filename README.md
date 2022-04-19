# raku Dan::Pandas
Dan::Pandas is the first specializer for the raku [Dan](https://github.com/p6steve/raku-Dan) **D**ata **AN**alysis Module.

Dan::Pandas uses the raku [Inline::Python](https://raku.land/cpan:NINE/Inline::Python) module to construct shadow Python objects and to wrap them to maintain the Dan API.
- Dan::Pandas::Series is a specialized Dan::Series
- Dan::Pandas::DataFrame is a specialized Dan::DataFrame

It adapts Dan maintaining **the base set of raku-style** datatype roles, accessors & methods - with few exceptions as noted below, a Dan::Pandas object can be a drop in replacement for it's Dan equivalent.

A script that uses Dan::Pandas should start with the following incantation:

```raku
#!/usr/bin/env raku
use lib '../lib';

use Dan;                #<== unlike a standalone Dan script, do NOT use the :ALL selector here
use Dan::Pandas;
```

A Dockerfile is provided based on the Python [jupyter/scipy-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-scipy-notebook) - look out for examples implemented as Jupyter notebooks on the raku Jupyter kernel. See installation section below...

Contributions via PR are very welcome - please see the backlog Issue, or just email p6steve@furnival.net to share ideas!

# SYNOPOSIS
The raku Dan [README.md](https://github.com/p6steve/raku-Dan/blob/main/README.md) is currently the best resource for the Dan API. This synopsis emphasizes the differences, more examples in [bin/synopsis-dan-pandas.raku](https://github.com/p6steve/raku-Dan/blob/main/bin/synopsis-dan-pandas.raku).
```raku
### Series ###

my \s = Series.new( [rand xx 5], index => <a b c d e>); 
#  -or- Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
#  -or- Series.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
say ~s;

#`[
a    0.297975
b    0.881274
c    0.868242
d    0.593949
e    0.141334
Name: anon, dtype: float64                   #<== Dan::Pandas::Series has a Python numpy dtype
#]

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

# Otherwise these do the same as raku Dan:
given s {
.dtype;
.ix;
.index;
.elems;
.map(*+2);
.splice(1,2,(j=>3));
}

my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;

# Operators are same as raku Dan also:
[+] s;  
s >>+>> 2; 
s >>+<< s; 
s[2];
s<c>;

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

# You can round-trip to/from Dan::Series:
my \u = s.Dan-Series;
say u.^name;               #Dan::Series [coerce from Dan::Pandas::Series]

my \v = Series.new( u );
say ~v.^name;              #Dan::Pandas::Series [construct from Dan::Series]

### DataFrames ###

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];
my \df = DataFrame.new( [[rand xx 4] xx 6], index => dates, columns => <A B C D> );
#  -or- DataFrame.new( [rand xx 5], columns => <A B C D>);
#  -or- DataFrame.new( [rand xx 5] );
say ~df;

say "---------------------------------------------";
# Data Accessors [row;col]
say df[0;0];
df[0;0] = 3;                #NOPE! <== unlike Dan, must use .pd method to set values, then optionally .pull


```


# Installation
- docker run -it p6steve/raku-dan:pandas-2022.02-arm64 (see Dockerfile)
- git clone https://github.com/p6steve/raku-Dan-Pandas.git
- cd raku-dan-pandas/bin/ && ./synopsis-dan-pandas.raku
