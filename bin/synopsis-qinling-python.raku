use Inline::Python;
my $py = Inline::Python.new();
$py.run('print("hello world")');

$py.run('import numpy as np');
$py.run('import pandas as pd');
say EVAL('pd.Series([1, 3, 5, np.nan, 6, 8])', :lang<Python>);

#use numpy:from<Python>;
#use pandas:from<Python>;

#my $s = pandas::Series([1, 3, 5, 6, 8]);
#say $s;

