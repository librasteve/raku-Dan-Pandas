# raku Dan::Pandas
Top level raku **D**ata **AN**alysis Module that provides **a base set of raku-style** datatype roles, accessors & methods, primarily:
- DataSlices
- Series
- DataFrames

A common basis for bindings such as ... [Dan::Pandas](https://github.com/p6steve/raku-Dan-Pandas) (via Inline::Python), Dan::Polars(tbd) (via NativeCall / Rust FFI), etc.

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
