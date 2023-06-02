#!/usr/bin/env raku
#t/01.ser.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 23;

use Dan;
use Dan::Pandas;

## Series

# Constructors

my \s0 = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
is ~s0, "0    1.0\n1    3.0\n2    5.0\n3    NaN\n4    6.0\n5    8.0\nName: mary, dtype: float64",    'new Series'; 

my \s1 = Series.new([0.239451e0 xx 5], index => <a b c d e>);
is ~s1, "a    0.239451\nb    0.239451\nc    0.239451\nd    0.239451\ne    0.239451\nName: anon, dtype: float64",                                     'explicit index';

my \s2 = Series.new([b=>1, a=>0, c=>2]);
is ~s2, "b    1\na    0\nc    2\nName: anon, dtype: int64",                        'Array of Pairs';

my \s3 = Series.new(5e0, index => <a b c d e>);
is ~s3, "a    5\nb    5\nc    5\nd    5\ne    5\nName: anon, dtype: int64",            'expand Scalar';

# Accessors

ok s3.ix == <a b c d e>,                                                     'Series.ix';
ok s3[1]==5,                                                                 'Positional';
ok s3{'b'}==5,                                                               'Associative not Int';
ok s3<c>==5,                                                                 'Associative <>';
ok s3{"c"}==5,                                                               'Associative {}';
ok s3.data == [5 xx 5],                                                      '.data';
ok s3.index.map(*.key) == 'a'..'e',                                          '.index keys';
ok s3.of ~~ Any,                                                             '.of';
ok s3.dtype eq "<class 'numpy.int64'>",                                      '.dtype';

# Operations 

ok s3[*] == 5 xx 5,                                                          'Whatever slice';
##ok s3[] == 5 xx 5,                                                           'Zen slice';
ok s3[*-1] == 5,                                                             'Whatever Pos';
ok s3[0..2] == 5 xx 3,                                                       'Range slice';
ok s3[2] + 2 == 7,                                                           'Element math';
ok s3.map(*+2) == 7 xx 5,                                                    '.map math';
ok ([+] s3) == 25,                                                           '[] operator';
ok s3.hyper ~~ HyperSeq,                                                     '.hyper';
ok (s3 >>+>> 2) == 7 xx 5,                                                   '>>+>>';
ok (s3 >>+<< s3) == 10 xx 5,                                                 '>>+<<';
my \t = s3; 
ok ([+] t) == 25,                                                           'assignment';


#done-testing;
