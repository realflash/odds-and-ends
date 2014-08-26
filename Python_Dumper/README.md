Python Dumper
=============

An equivalent of Perl's Data::Dumper for python. To use, put the DUmper directory in the same directory as your python code. Then:

    from Dumper import dumper
    
    d = Dumper()
    print d.dump(object)

Thanks to https://gist.github.com/passos/1071857
