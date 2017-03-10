## quadraG
quadraG: an open and parallel tools for automated G-quadruplexes analysis

Copyright 2017 Jitendra Narayan <jnarayan81@gmail.com> ; Rahul Agarwal <vibes1002003@gmail.com>

# LICENSE

This file is part of quadrqG.

quadraG is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

quadraG is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with quadraG, in a file called COPYING. If not, see <http://www.gnu.org/licenses/>.

# INSTALLATION

See INSTALLATION. This is a standard setuptools setup, if you already know the procedure.

 1) Edit setup.sh and change $SWEETPATH to the full directory where you've placed the package.
 
 2) To automatically place the package into your environment, add
    > source <path to>/setup.sh 
    to your .bash_profile

Be sure to source your .bash_profile (or just setup.sh) before using quadraG

USING PERL 5.x

quadraG does not support Perl 5.x, and no plans exist to provide such support. For a strong biological analysis package for perl 5, see perl https://www.perl.org/ and bioperl: http://bioperl.org/

# DOCUMENTATION

For documentation, see quadrqG_manual.pdf in the base project folder.

This documentation may be out of date depending on whether or not the developers did their job and re-generated the documentation before the release. If you suspect that the documentation is out of date, or if you are using code from the repository (and not from a release), you can re-generate the documentation or contact the authors.

# RELEASE HISTORY

0.1.O - 30 Jun 2017

# OUTPUT FORMAT

 quadraG outfile columns:
 
    * CHROM       Reference entry where quadraG occurs
    * OUTERSTART  The 5' most boundary estimate of where quadraG begins
    * START       Best guess as the the exact start of the quadraG
    * INNERSTART  The 3' most boundary estimate of where quadraG begins
    * INNEREND    The 5' most boundary estimate of where quadraG ends
    * End         Best guess as the the exact end of the quadraG
    * OUTEREND    The 3' most boundary estimate of where the quadraG ends
    * TYPE        Variant type. One of MIS, INS, INSZ, or DEL
    * SIZE        Estimate size of the quadraG
    * INFO        More information associated with the calls

 quadraG result columns:

    * ID        Unique identifier of the call
    * CHROM     Reference entry where q4 occurs
    * START     Start point
    * END       End point
    * EXSEQ     Average amount of sequence left between
    * GFF       GFF entry
 
# ANNOTATION DESCRIPTIONS
Coming Soon

# EXTRA
 Coming Soon

# FAQ

Who can I report bugs to or ask questions?
Please report your issues to ticketing system.

# CONTRIBUTION

Feel free to clone this repository and use it under the licensing terms.

Additionally, as the project is on github, you may submit patches, ticket requests, edit the wiki, send pull requests - anything you like and have the permissions to do. I will enjoy any and all contributions, I'm sure! :)

As always, you can contact the authors at <jnarayan81@gmail.com> or <vibes1002003@gmail.com>.
