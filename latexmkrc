# SPDX-License-Identifier: MIT
# Copyright (c) 2026 P.O. Bolduc. See LICENSE.
#
# Project build settings. The build rules are shared by every solution manual
# and live in the framework folder; outputs stay in this project
# (build/, Figures/*.pdf and the final PDF in this folder).

# Framework folder, relative to this file. When the template repository is a
# Git submodule (e.g. at template/), use 'template/solution-manual'.
$framework_dir = 'solution-manual';

use File::Spec;
my $shared = File::Spec->rel2abs("$framework_dir/latexmkrc");
do $shared or die "Could not load $shared: ", ($@ || $!), "\n";

# Project-specific latexmk settings can be added below.
