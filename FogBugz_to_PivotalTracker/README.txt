Look at the code first to check it's going to do what you want. This script is to give you a head start. Patches are gladly accepted, but I'm unlikely to work on any issues you raise.

USAGE
-----
1. In FogBugz, select the issues you want to export
2. Click More > Export cases to Excel
3. Run this script:

./fb_to_pt.pl <CSV-file>

KNOWN ISSUES
------------
1. FogBugz only exports the last comment. You will not get the original description of the case.
