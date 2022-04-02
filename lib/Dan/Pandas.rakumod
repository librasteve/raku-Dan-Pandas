unit module Dan::Pandas:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

#`[TODOs
- Series
-- constructors
-- accessors
-- pd methods
-- pull (to Raku-side attrs)
-- splice
-- concat
-- 2-arity pd methods 
-- coerce to Dan::Series (.Dan::Series)
-- new from Dan::Series
- DataFrame
-- constructors
-- accessors
^^ DONE
-- pd methods
-- pull (to Raku-side attrs)
-- splice
-- concat
-- 2-arity pd methods 
-- coerce to Dan::Series (.Dan::Series)
-- new from Dan::Series
- Big Pic
-- ix index reindex behaviour
-- duplicate keys
-- disjoint keys
-- review Dan::Series to better align codebases (2x2)
--- remove name from Dan::Series::DataFrame
- v2
--? parse Pandas methods (viz. https://stackoverflow.com/questions/71667086)
--? offer dyadic operators (eg. +-*/ for Series & DataFrames)
--? support Python Timeseries / DatetimeIndex
#]

use Dan;
use Inline::Python;

# generates default column labels
constant @alphi = 'A'..∞; 

# sorts Hash by value, returns keys (poor woman's Ordered Hash)
sub sbv( %h --> Seq ) is export {
    %h.sort(*.value).map(*.key)
}

#| singleton pattern for shared Python context 
#| viz. https://docs.raku.org/language/classtut

class Py {
    my  Py $instance;
    has Inline::Python $.py;

    method new {!!!}

    submethod instance {
	unless $instance {
            $instance = Py.bless( py => Inline::Python.new ); 
 	    $instance.py.run('import numpy as np');
	    $instance.py.run('import pandas as pd');
	}
        $instance;
    }
}

role Series does Positional does Iterable is export {

    ## attrs for construct and pull only: not synched to Python side ##
    has Str	$.name;
    has Any     @.data;
    has Int     %!index;

    has $!py = Py.instance.py; 	  
    has $.po;			  #each instance has own Python Series obj 

    ### Constructors ###
 
    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }

    # Real (scalar) data arg => populate Array & redispatch
    multi method new( Real:D :$data, :$index, *%h ) {
        die "index required if data ~~ Real" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Str (scalar) data arg => populate Array & redispatch
    multi method new( Str:D :$data, :$index, *%h ) {
        die "index required if data ~~ Str" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Date (scalar) data arg => populate Array & redispatch
    multi method new( Date:D :$data, :$index, *%h ) {
        die "index required if data ~~ Date" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # from Dan::Series 
    multi method new( Dan::Series:D \s ) {
        samewith( name => s.name, data => s.data, index => s.index )
    }


    submethod BUILD( :$name, :@data, :$index ) {
        $!name = $name // 'anon';
	@!data = @data;

	if $index {
            if $index !~~ Hash {
                %!index = $index.map({ $_ => $++ })
	    } else {
	        %!index = $index
	    }
	}
    }

    method prep-args {

	my $args  = "[{@!data.join(', ')}]";
	   $args ~~ s:g/NaN/np.nan/;
	   $args ~= ", index=['{%!index.&sbv.join("', '")}']"   if %!index; 	
	   $args ~= ", name=\"$!name\""   	      		if $!name;

    }

    method TWEAK {

	# handle data => Array of Pairs 

        if @!data.first ~~ Pair {

            die "index not permitted if data is Array of Pairs" if %!index;

            @!data = gather {
                for @!data -> $p {
                    take $p.value;
                    %!index{$p.key} = $++
                }
            }.Array
	}

	# handle implicit index

	if ! %!index {
	    %!index = gather {
		for 0..^@!data {
		    take ( $_ => $_ )
		}
	    }.Hash
	}
  
	my $args = self.prep-args;

# since Inline::Python will not pass a Series class back and forth
# we make and instantiate a standard class 'RakuSeries' as container
# and populate methods over in Python to condition the returns as 
# supported datastypes (Int, Str, Array, Hash, etc)

my $py-str = qq{

class RakuSeries:
    def __init__(self):
        self.series = pd.Series($args)
        #print(self.series)

    def rs_str(self):
        return(str(self.series))

    def rs_dtype(self):
        return(str(self.series.dtype.type))

    def rs_index(self):
        return(self.series.index)

    def rs_reindex(self, new_index):
        result = self.series.reindex(new_index)
        return(result)

    def rs_size(self):
        return(self.series.size)

    def rs_values(self):
        array = self.series.values
        result = array.tolist()
        return(result)

    def rs_eval(self, exp):
        result = eval('self.series' + exp)
        print(result) 

    def rs_eval2(self, exp, other):
        result = eval('self.series' + exp + '(other.series)')
        print(result) 

    def rs_exec(self, exp):
        exec('self.series' + exp)

    def rs_push(self, args):
        self.series = eval('pd.Series(' + args + ')')

};

	$!py.run($py-str);
	$!po = $!py.call('__main__', 'RakuSeries');
    }

    #### Info Methods #####

    method Str { 
	$!po.rs_str()
    }

    method dtype {
	$!po.rs_dtype()
    }

    #| get index as Hash
    method index {
	my @keys = $!po.rs_index();
        @keys.map({ $_ => $++ }).Hash
    }

    #| get index as Array
    multi method ix {
	$!po.rs_index()
    }

    method Dan-Series {
	$.pull;
	Dan::Series.new( :$!name, :@!data, :%!index )
    }

    #### Sync Methods #####
    #### Pull & Push  #####

    #| set raku attrs to rs_array / rs_index
    method pull {
	%!index = $.index;
	@!data = $!po.rs_values;
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    # TODO - adjust Dan::Series index / ix behaviour to match Pandas (same API)

    #| set index from Array (Dan::Series style) 
    multi method ix( $new-index ) {
	$!po.rs_reindex( $new-index )
    }

    #| reindex from Array (Pandas style)
    method reindex( @index ) {
	my $rese  = $!po.rs_reindex( $@index );
	my @data  = $rese.values; 
	Series.new( :@data, :@index )
    }

    #| get self as Array of Pairs
    multi method aop {
	$.pull;
        self.ix.map({ $_ => @!data[$++] })
    }

    #| set data and index from Array of Pairs
    multi method aop( @aop ) {
        %!index = @aop.map({$_.key => $++});
        @!data  = @aop.map(*.value);

	my $args = self.prep-args;
	$!po.rs_push($args)
    }

    #| splice as Array of values or Array of Pairs
    #| viz. https://docs.raku.org/routine/splice
    method splice( Dan::Pandas::Series:D: $start = 0, $elems?, *@replace ) {
        given @replace {
            when .first ~~ Pair {
                my @aop = self.aop;
                my @res = @aop.splice($start, $elems//*, @replace);
                self.aop: @aop;
                @res
            }
            default {
                my @res = @!data.splice($start, $elems//*, @replace); 
                self.fillna; 
                @res
            }
        }
    }

    #| set empty data slots to Nan
    method fillna {
        self.aop.grep(! *.value.defined).map({ $_.value = NaN });
    }

    #| drop index and data when Nan
    method dropna {
        self.aop: self.aop.grep(*.value ne NaN);
    }

    #| drop index and data when empty 
    method dropem {
        self.aop: self.aop.grep(*.value.defined).Array;
    }

    # concat
    method concat( Dan::Pandas::Series:D $dsr ) {
	$.pull;

        %!index.map({ 
            if $dsr.index{$_.key}:exists {
                warn "duplicate key {$_.key} not permitted" 
            } 
        });

        my $start = %!index.elems;
        my $elems = $dsr.index.elems;
        my @replace = $dsr.aop;

        self.splice: $start, $elems, @replace;    
        self
    }

    ### Pandas Methods ###

    multi method pd( $exp ) {
	if $exp ~~ /'='/ {
	    $!po.rs_exec( $exp )
	} else {
	    $!po.rs_eval( $exp )
	}
    }

    multi method pd( $exp, Dan::Pandas::Series:D $other ) {
	$!po.rs_eval2( $exp, $other.po )
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Any
    }
    method elems {
	$!po.rs_size()
    }
    method AT-POS( $p ) {
	$.pull;
        @!data[$p]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < self.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
	$.pull;
        @!data.iterator
    }
    method flat {
	$.pull;
        @!data.flat
    }
    method lazy {
	$.pull;
        @!data.lazy
    }
    method hyper {
	$.pull;
        @!data.hyper
    }

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # DataSlice just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
	$.pull;
        @!data[%.index{$k}]
    }
    method EXISTS-KEY( $k ) {
	$.pull;
        %.index{$k}:exists
    }

}

role DataFrame does Positional does Iterable is export {
    has Any         @.data;             #redo 2d shaped Array when [; ] implemented
    has Int         %!index;            #row index
    has Int         %!columns;          #column index

    has $!py = Py.instance.py; 	  
    has $.po;			  #each instance has own Python DataFrame obj 

    ### Constructors ###
 
    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }

    submethod BUILD( :@data, :$index, :$columns ) {
	@!data = @data;

	if $index {
            if $index !~~ Hash {
                %!index = $index.map({ $_ => $++ })
	    } else {
	        %!index = $index
	    }
	}

	if $columns {
            if $columns !~~ Hash {
                %!columns = $columns.map({ $_ => $++ })
	    } else {
	        %!columns = $columns
	    }
	}
    }

    # helper functions for TWEAK

    method load-from-series( :$row-count, *@series ) {
        loop ( my $i=0; $i < @series; $i++ ) {

            #@!dtypes.push: @series[$i].dtype;   #use Pandas to autoset dtypes

            my $key = @series[$i].name // @alphi[$i];
            %!columns{ $key } = $i;

            loop ( my $j=0; $j < $row-count; $j++ ) {
                @!data[$j;$i] = @series[$i][$j]                             #TODO := with BIND-POS
            }
        }
    }

    method load-from-slices( @slices ) {
        loop ( my $i=0; $i < @slices; $i++ ) {

            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }
    }

    method prep-args {
	my @rows = gather {
            loop ( my $i=0; $i < @!data; $i++ ) {
		take "[{@!data[$i;*].join(', ')}]"
            }
	}

	my $args  = "[{@rows.join(', ')}]";
	   $args ~~ s:g/NaN/np.nan/;
	   $args ~= ", index=['{%!index.&sbv.join("', '")}']"       if %!index; 	
	   $args ~= ", columns=['{%!columns.&sbv.join("', '")}']"   if %!columns; 	
    }
  
    method TWEAK {

        given @!data.first {

            # data arg is 1d Array of Pairs (label => Series)
            when Pair {
                die "columns / index not permitted if data is Array of Pairs" if %!index || %!columns;

                my $row-count = 0;
                @!data.map( $row-count max= *.value.elems );

                my @index  = 0..^$row-count;
                my @labels = @!data.map(*.key);

                # make (or update) each Series with column key as name, index as index
                my @series = gather {
                    for @!data -> $p {
                        my $name = ~$p.key;
                        given $p.value {
                            # handle Series/Array with row-elems (auto index)   #TODO: avoid Series.new
                            when Series { take Series.new( $_.data, :$name, dtype => ::($_.dtype) ) }
                            when Array  { take Series.new( $_, :$name ) }

                            # handle Scalar items (set index to auto-expand)    #TODO: lazy expansion
                            when Str|Real|Date { take Series.new( $_, :$name, :@index ) }
                        }
                    }
                }.Array;

                # clear and load data
                @!data = [];
                $.load-from-series: row-count => +@index, |@series;

                # make index Hash (row label => pos) 
                my $j = 0;
                %!index{~$j} = $j++ for ^@index;

                # make columns Hash (col label => pos) 
                my $i = 0;
                %!columns{@labels[$i]} = $i++ for ^@labels;
            } 

            # data arg is 1d Array of Series (cols)
            when Series {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                my $row-count = @!data.first.elems;
                my @series = @!data; 

                # clear and load data (and columns)
                @!data = [];
                $.load-from-series: :$row-count, |@series;

                # make index Hash
                %!index = @series.first.index;
            }

            # data arg is 1d Array of DataSlice (rows)
            when Dan::DataSlice {
                my @slices = @!data; 

                # clear and load data (and index)
                @!data = [];
                $.load-from-slices: @slices;

                # make columns Hash
                %!columns = @slices.first.index;
            }

            # data arg is 2d Array (already) 
            default {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                if ! %!index {
                    [0..^@!data.elems].map( {%!index{$_.Str} = $_} );
                }
                if ! %!columns {
                    @alphi[0..^@!data.first.elems].map( {%!columns{$_} = $++} ).eager;
                }
                #no-op
            } 
        }

	my $args = self.prep-args;

# since Inline::Python will not pass a DataFrame class back and forth
# we make and instantiate a standard class 'RakuDataFrame' as container
# and populate methods over in Python to condition the returns as 
# supported datastypes (Int, Str, Array, Hash, etc)

my $py-str = qq{

class RakuDataFrame:
    def __init__(self):
        self.dataframe = pd.DataFrame($args)
        #print(self.dataframe)

    def rd_str(self):
        return(str(self.dataframe))

    def rd_dtype(self):
        return(str(self.dataframe.dtype.type))

    def rd_index(self):
        return(self.dataframe.index)

    def rd_columns(self):
        return(self.dataframe.columns)

    def rd_reindex(self, new_index):
        result = self.dataframe.reindex(new_index)
        return(result)

    def rd_size(self):
        return(self.dataframe.size)

    def rd_values(self):
        array = self.dataframe.values
        result = array.tolist()
        return(result)

    def rd_eval(self, exp):
        result = eval('self.dataframe' + exp)
        print(result) 

    def rd_eval2(self, exp, other):
        result = eval('self.dataframe' + exp + '(other.dataframe)')
        print(result) 

    def rd_exec(self, exp):
        exec('self.dataframe' + exp)

    def rd_push(self, args):
        self.dataframe = eval('pd.DataFrame(' + args + ')')

    def rd_transpose(self):
        self.dataframe = self.dataframe.T

    def rd_shape(self):
        return(self.dataframe.shape)

    def rd_describe(self):
        print(self.dataframe.describe())

};

	$!py.run($py-str);
	$!po = $!py.call('__main__', 'RakuDataFrame');

    }
    #### Info Methods #####

    method Str { 
	$!po.rd_str()
    }

#`[[
    method dtype {
	$!po.rs_dtype()
    }
#]]
#`[[
    method Dan-Series {
	$.pull;
	Dan::Series.new( :$!name, :@!data, :%!index )
    }
#]]

    #| get index as Array
    multi method ix {
	$!po.rd_index()
    }

    #| get index as Hash
    method index {
	my @keys = $!po.rd_index();
        @keys.map({ $_ => $++ }).Hash
    }

    #| get columns as Array
    multi method cx {
	$!po.rd_columns()
    }

    #| get columns as Hash
    method columns {
	my @keys = $!po.rd_columns();
        @keys.map({ $_ => $++ }).Hash
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#
#`[
    #| set (re)index from Array
    multi method ix( @new-index ) {
        %.index.keys.map: { %.index{$_}:delete };
        @new-index.map:   { %.index{$_} = $++  };
    }

    #| set columns (relabel) from Array
    multi method cx( @new-labels ) {
        %.columns.keys.map: { %.columns{$_}:delete };
        @new-labels.map:    { %.columns{$_} = $++  };
    }
#]

    #### Sync Methods #####
    #### Pull & Push  #####

    #| set raku attrs to rd_array / rd_index / rd_columns
    method pull {
	%!index = $.index;
	%!columns = $.columns;
	@!data = $!po.rd_values;
    }

    ### Mezzanine methods ###  
    #   (these use Python)  #

    method T {
	$!po.rd_transpose();
	self
    }

    method shape {
	$!po.rd_shape()
    }

    method describe {
	$!po.rd_describe()
    }

    method fillna {
        self.map(*.map({ $_ //= NaN }).eager);
    }

    method series( $k ) {
        self.[*]{$k}
    }

    method sort( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= sort: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    method grep( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= grep: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional
    # delegates semilist [; ] value element access to @!data
    # override list [] access anyway

    method of {
        Any
    }
    method elems {
	$.pull;
        @!data.elems
    }
    method AT-POS( $p, $q? ) {
	$.pull;
        @!data[$p;$q // *]
    }
    method EXISTS-POS( $p ) {
	$.pull;
        0 <= $p < @!data.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
	$.pull;
        @!data.iterator
    }
    method flat {
	$.pull;
        @!data.flat
    }
    method lazy {
	$.pull;
        @!data.lazy
    }
    method hyper {
	$.pull;
        @!data.hyper
    }
}

#`[[

### Declarations & Helper Functions ###

# set mark for index/column duplicates
constant $mark = '⋅'; # unicode Dot Operator U+22C5
my regex notmark { <-[⋅]> }

role Categorical is Series is export(:ALL) {
    # Output
    method dtype {
        Str.^name
    }
}

role DataFrame does Positional does Iterable is export(:ALL) {
    has Str         $.name is rw = 'anon';
    has Any         @.data = [];        #redo 2d shaped Array when [; ] implemented
    has Int         %.index;            #row index
    has Int         %.columns;          #column index
    has Str         @.dtypes;

    ### Constructors ###

    # helper functions
    method load-from-series( :$row-count, *@series ) {
        loop ( my $i=0; $i < @series; $i++ ) {

            @!dtypes.push: @series[$i].dtype;

            my $key = @series[$i].name // @alphi[$i];
            %!columns{ $key } = $i;

            loop ( my $j=0; $j < $row-count; $j++ ) {
                @!data[$j;$i] = @series[$i][$j]                             #TODO := with BIND-POS
            }
        }
    }

    method load-from-slices( @slices ) {
        loop ( my $i=0; $i < @slices; $i++ ) {

            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }
    }

    method TWEAK {
        given @!data.first {

            # data arg is 1d Array of Pairs (label => Series)
            when Pair {
                die "columns / index not permitted if data is Array of Pairs" if %!index || %!columns;

                my $row-count = 0;
                @!data.map( $row-count max= *.value.elems );

                my @index  = 0..^$row-count;
                my @labels = @!data.map(*.key);

                # make (or update) each Series with column key as name, index as index
                my @series = gather {
                    for @!data -> $p {
                        my $name = ~$p.key;
                        given $p.value {
                            # handle Series/Array with row-elems (auto index)   #TODO: avoid Series.new
                            when Series { take Series.new( $_.data, :$name, dtype => ::($_.dtype) ) }
                            when Array  { take Series.new( $_, :$name ) }

                            # handle Scalar items (set index to auto-expand)    #TODO: lazy expansion
                            when Str|Real|Date { take Series.new( $_, :$name, :@index ) }
                        }
                    }
                }.Array;

                # clear and load data
                @!data = [];
                $.load-from-series: row-count => +@index, |@series;

                # make index Hash (row label => pos) 
                my $j = 0;
                %!index{~$j} = $j++ for ^@index;

                # make columns Hash (col label => pos) 
                my $i = 0;
                %!columns{@labels[$i]} = $i++ for ^@labels;
            } 

            # data arg is 1d Array of Series (cols)
            when Series {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                my $row-count = @!data.first.elems;
                my @series = @!data; 

                # clear and load data (and columns)
                @!data = [];
                $.load-from-series: :$row-count, |@series;

                # make index Hash
                %!index = @series.first.index;
            }

            # data arg is 1d Array of DataSlice (rows)
            when DataSlice {
                my @slices = @!data; 

                # clear and load data (and index)
                @!data = [];
                $.load-from-slices: @slices;

                # make columns Hash
                %!columns = @slices.first.index;
            }

            # data arg is 2d Array (already) 
            default {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                if ! %!index {
                    [0..^@!data.elems].map( {%!index{$_.Str} = $_} );
                }
                if ! %!columns {
                    @alphi[0..^@!data.first.elems].map( {%!columns{$_} = $++} ).eager;
                }
                #no-op
            } 
        }
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| get index as Array (ordered by %.index.values)
    multi method ix {
        %!index.&sbv
    }

    #| set (re)index from Array
    multi method ix( @new-index ) {
        %.index.keys.map: { %.index{$_}:delete };
        @new-index.map:   { %.index{$_} = $++  };
    }

    #| get columns as Array (ordered by %.column.values)
    multi method cx {
        %!columns.&sbv
    }

    #| set columns (relabel) from Array
    multi method cx( @new-labels ) {
        %.columns.keys.map: { %.columns{$_}:delete };
        @new-labels.map:    { %.columns{$_} = $++  };
    }

    ### Splicing ###

    #| reset attributes
    method reset( :$axis ) {

        @!data = [];

        if ! $axis {
            %!index = %()
        } else {
            @!dtypes  = [];
            %!columns = %()
        }
    }

    #| get as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method get-ap( :$axis, :$pair ) {
        given $axis, $pair {
            when 0, 0 {
                self.[*]
            }
            when 0, 1 {
                my @slices = self.[*];
                self.ix.map({ $_ => @slices[$++] })
            }
            when 1, 0 {
                self.cx.map({self.series($_)}).Array
            }
            when 1, 1 {
                my @series = self.cx.map({self.series($_)}).Array;
                self.cx.map({ $_ => @series[$++] })
            }
        }
    }

    #| set from Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method set-ap( :$axis, :$pair, *@set ) {

        self.reset: :$axis;

        given $axis, $pair {
            when 0, 0 {                         # row - array
                self.load-from-slices: @set
            }
            when 0, 1 {                         # row - aops 
                self.load-from-slices: @set.map(*.value);
                self.ix: @set.map(*.key)
            }
            when 1, 0 {                         # col - array
                self.load-from-series: row-count => @set.first.elems, |@set
            }
            when 1, 1 {                         # col - aops
                self.load-from-series: row-count => @set.first.value.elems, |@set.map(*.value);
                self.cx: @set.map(*.key)
            }
        }
    }

    sub clean-axis( :$axis ) {
        given $axis {
            when ! .so || /row/ { 0 }
            when   .so || /col/ { 1 }
        }
    }

    #| splice as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    #| viz. https://docs.raku.org/routine/splice
    method splice( DataFrame:D: $start = 0, $elems?, :ax(:$axis) is copy, *@replace ) {

           $axis = clean-axis(:$axis);
        my $pair = @replace.first ~~ Pair ?? 1 !! 0;

        my @wip = self.get-ap: :$axis, :$pair;
        my @res = @wip.splice: $start, $elems//*, @replace;   # just an Array splice
                  self.set-ap: :$axis, :$pair, @wip;

        @res
    }

    # concat
    method concat( DataFrame:D $dfr, :ax(:$axis) is copy,           #TODO - refactor for speed?   
                     :jn(:$join) = 'outer', :ii(:$ignore-index) ) {

        $axis = clean-axis(:$axis);
        my $ax = ! $axis;        #AX IS INVERSE AXIS

        my ( $start,   $elems   );
        my ( @left,    @right   );
        my ( $l-empty, $r-empty );
        my ( %l-drops, %r-drops );

        if ! $axis {            # row-wise

            # set extent of main slice 
            $start = self.index.elems;
            $elems = $dfr.index.elems;

            # take stock of cols
            @left   = self.cx;
            @right  = $dfr.cx;

            # make some empties
            $l-empty = Series.new( NaN, index => [self.ix] );
            $r-empty = Series.new( NaN, index => [$dfr.ix] );

            # load drop hashes
            %l-drops = self.columns;
            %r-drops = $dfr.columns;

        } else {                # col-wise

            # set extent of main slice
            $start = self.columns.elems;
            $elems = $dfr.columns.elems;

            # take stock of rows
            @left   = self.ix;
            @right  = $dfr.ix;

            # make some empties
            $l-empty = DataSlice.new( data => [NaN xx self.cx.elems], index => [self.cx] );
            $r-empty = DataSlice.new( data => [NaN xx $dfr.cx.elems], index => [$dfr.cx] );

            # load drop hashes
            %l-drops = self.index;
            %r-drops = $dfr.index;

        }

        my @inner  = @left.grep(  * ∈ @right );
        my @l-only = @left.grep(  * ∉ @inner );
        my @r-only = @right.grep( * ∉ @inner );
        my @outer  = |@l-only, |@r-only;

        # helper functions for adjusting columns

        sub add-ronly-to-left {
            for @r-only -> $name {
                self.splice: :$ax, *, *, ($name => $l-empty)
            }
        }
        sub add-lonly-to-right {
            for @l-only -> $name {
                $dfr.splice: :$ax, *, *, ($name => $r-empty)
            }
        }
        sub drop-outers-from-left {
            for @l-only -> $name {
                self.splice: :$ax, %l-drops{$name}, 1
            }
        }
        sub drop-outers-from-right {
            for @r-only -> $name {
                $dfr.splice: :$ax, %r-drops{$name}, 1
            }
        }

        # re-arrange left and right 
        given $join {
            when /^o/ {          #outer
                add-ronly-to-left;
                add-lonly-to-right;
            }
            when /^i/ {          #inner
                drop-outers-from-left;
                drop-outers-from-right;
            }
            when /^l/ {          #left
                add-lonly-to-right;
                drop-outers-from-right;
            }
            when /^r/ {          #right
                add-ronly-to-left;
                drop-outers-from-left;
            }
        }

        # load new row/col info
        my ( @new-left, @new-right );
        my ( %new-left, %new-right );

        if ! $axis {    #row-wise
            @new-left  = self.cx;       @new-right = $dfr.cx;
            %new-left  = self.columns;  %new-right = $dfr.columns;
        } else {        #column-wise
            @new-left  = self.ix;       @new-right = $dfr.ix;
            %new-left  = self.index;    %new-right = $dfr.index;
        }

        # align new right to new left
        for 0..^+@new-left -> $i {
            if @new-left[$i] ne @new-right[$i] {
                my @mover = $dfr.splice: :$ax, %new-right{@new-left[$i]}, 1; 
                $dfr.splice: :$ax, $i, 0, @mover; 
            }
        }

        # load name duplicates
        my $dupes = ().BagHash;
        my ( @new-main, %new-main );

        if ! $axis {    #row-wise
            @new-main = self.ix;
            %new-main = self.index;
        } else {        #column-wise
            @new-main = self.cx;
            %new-main = self.columns;
        }

        @new-main.map({ $_ ~~ / ^ (<notmark>*) /; $dupes.add(~$0) }); 

        # load @replace as array of pairs
        my @replace = $dfr.get-ap( :$axis, pair => 1 );

        # handle name duplicates
        @replace.map({ 
            if %new-main{$_.key}:exists {
                #warn "duplicate key {$_.key}";

                $_.key ~~ / ^ (<notmark>*) /;
                my $b-key = ~$0;
                my $n-key = $b-key ~ $mark ~ $dupes{$b-key};

                $_ = $n-key => $_.value; 
                $dupes{$b-key}++;
            } 
        });

        # do the main splice
        self.splice: :$axis, $start, $elems, @replace;    

        # handle ignore-index
        if $ignore-index {
            if ! $axis {
                my $size = self.ix.elems;
                self.index = %();
                self.index{~$_} = $_ for 0..^$size
            } else {
                my $size = self.cx.elems;
                self.columns = %();
                self.columns{~$_} = $_ for 0..^$size
            }
        } 

        self
    }

    ### Mezzanine methods ###  
    # (these use Accessors) #

    method fillna {
        self.map(*.map({ $_ //= NaN }).eager);
    }

    method T {
        DataFrame.new( data => ([Z] @.data), index => %.columns, columns => %.index )
    }

    method series( $k ) {
        self.[*]{$k}
    }

    method sort( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= sort: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    method grep( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= grep: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    method describe {
        my @series = $.cx.map({ $.series: $_ });
        my @data = @series.map({ $_.describe }); 

        DataFrame.new( :@data )
    }

    ### Output methods ###

    method shape {
        self.ix.elems, self.cx.elems
    }

    method dtypes {
        my @labels = self.columns.&sbv;

        if ! @!dtypes {
            my @series = @labels.map({ self.series($_) });
              @!dtypes = @series.map({ ~$_.dtype });
        }

        gather {
            for @labels -> $k {
                take $k ~ ' => ' ~ @!dtypes[$++]
            }
        }.join("\n")
    }

    method Str {
        # i is inner,       j is outer
        # i is cols across, j is rows down
        # i0 is index col , j0 is row header

        # headers
        my @row-hdrs = %!index.&sbv;
        my @col-hdrs = %!columns.&sbv;
           @col-hdrs.unshift: '';

        # rows (incl. row headers)
        my @out-rows = @!data.deepmap( * ~~ Date ?? *.Str !! * );
           @out-rows.map({ 
                $_ .= Array; 
                $_.unshift: @row-hdrs.shift
            });

        # set table options 
        my %options = %(
            rows => {
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
            headers => {
                top_border           => '',
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
            footers => {
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
        );

        my @table = lol2table(@col-hdrs, @out-rows, |%options);
        @table.join("\n")
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional
    # delegates semilist [; ] value element access to @!data
    # override list [] access anyway

    method of {
        Any
    }
    method elems {
        @!data.elems
    }
    method AT-POS( $p, $q? ) {
        @!data[$p;$q // *]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < @!data.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
        @!data.iterator
    }
    method flat {
        @!data.flat
    }
    method lazy {
        @!data.lazy
    }
    method hyper {
        @!data.hyper
    }
}
#]]

### Postfix '^' as explicit subscript chain terminator

multi postfix:<^>( Dan::DataSlice @ds ) is export {
    DataFrame.new(@ds) 
}
multi postfix:<^>( Dan::DataSlice $ds ) is export {
    DataFrame.new(($ds,)) 
}

### Override first subscript [i] to make Dan::DataSlices (rows)

#| provides single Dan::DataSlice which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( DataFrame:D $df, Int $p ) is export {
    Dan::DataSlice.new( data => $df.data[$p;*], index => $df.columns, name => $df.index.&sbv[$p] )
}

# helper
sub make-aods( $df, @s ) {
    my Dan::DataSlice @ = @s.map({
        Dan::DataSlice.new( data => $df.data[$_;*], index => $df.columns, name => $df.index.&sbv[$_] )
    })
}

#| slices make Array of Dan::DataSlice objects
multi postcircumfix:<[ ]>( DataFrame:D $df, @s where Range|List ) is export {
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, WhateverCode $p ) is export {
    my @s = $p( |($df.elems xx $p.arity) );
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, Whatever ) is export {
    my @s = 0..^$df.elems; 
    make-aods( $df, @s )
}


### Override second subscript [j] to make DataFrame

# helper
sub sliced-slices( @aods, @s ) {
    gather {
        @aods.map({ take Dan::DataSlice.new( data => $_[@s], index => $_.index.&sbv[@s], name => $_.name )}) 
    }   
}
sub make-series( @sls ) {
    my @data  = @sls.map({ $_.data[0] });
    my @index = @sls.map({ $_.name[0] });
    my $name  = @sls.first.index.&sbv[0];

    Series.new( :@data, :@index, :$name )
}

#| provides single Series which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( Dan::DataSlice @aods , Int $p ) is export {
    make-series( sliced-slices(@aods, ($p,)) )
}

#| make DataFrame from sliced Dan::DataSlices 
multi postcircumfix:<[ ]>( Dan::DataSlice @aods , @s where Range|List ) is export {
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( Dan::DataSlice @aods, WhateverCode $p ) is export {
    my @s = $p( |(@aods.first.elems xx $p.arity) );
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( Dan::DataSlice @aods, Whatever ) is export {
    my @s = 0..^@aods.first.elems;
    DataFrame.new( sliced-slices(@aods, @s) )
}

### Override first assoc subscript {i}

multi postcircumfix:<{ }>( DataFrame:D $df, $k ) is export {
    $df[$df.index{$k}]
}
multi postcircumfix:<{ }>( DataFrame:D $df, @ks ) is export {
    $df[$df.index{@ks}]
}

### Override second subscript [j] to make DataFrame

multi postcircumfix:<{ }>( Dan::DataSlice @aods , $k ) is export {
    my $p = @aods.first.index{$k};
    make-series( sliced-slices(@aods, ($p,)) )
}
multi postcircumfix:<{ }>( Dan::DataSlice @aods , @ks ) is export {
    my @s = @aods.first.index{@ks};
    DataFrame.new( sliced-slices(@aods, @s) )
}

#EOF

