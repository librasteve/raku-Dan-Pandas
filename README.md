# raku Dan::Pandas
Dan::Pandas is the first specializer for the raku [Dan](https://github.com/p6steve/raku-Dan) **D**ata **AN**alysis Module.

Dan::Pandas uses the raku Inline::Python module to construct shadow Python objects and to wrap them to maintain the Dan API.
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



It's rather a zen concept since raku contains many Data Analysis constructs & concepts natively anyway (see note 7 below)

Contributions via PR are very welcome - please see the backlog Issue, or just email p6steve@furnival.net to share ideas!

# SYNOPOSIS
more examples in [bin/synopsis.raku](https://github.com/p6steve/raku-Dan/blob/main/bin/synopsis-dan.raku)
```raku
### Series ###

my \s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
#  -or- Series.new( [rand xx 5], index => <a b c d e>);
#  -or- Series.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
say ~s;
```


# Installation
- docker run -it p6steve/raku-dan:pandas-2022.02-arm64 (see Dockerfile)
- git clone https://github.com/p6steve/raku-Dan-Pandas.git
- cd raku-dan-pandas/bin/ && ./synopsis-dan-pandas.raku
