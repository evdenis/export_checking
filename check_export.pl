#!/usr/bin/perl

# check_export.pl
# Copyright (C) 2012 Denis Efremov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use 5.10.0;
use feature qw(say);

use Getopt::Long qw(:config gnu_getopt);

my $pattern = '';

GetOptions(
   'init|i!'   => sub { if ( $pattern !~ m/__init/ ) { $pattern = $pattern . '(?:__init)|'; } },
   'exit|e!'   => sub { if ( $pattern !~ m/__exit/ ) { $pattern = $pattern . '(?:__exit)|'; } },
   'inline|n!' => sub { if ( $pattern !~ m/inline/ ) { $pattern = $pattern . '(?:inline)|'; } },
   'static|s!' => sub { if ( $pattern !~ m/static/ ) { $pattern = $pattern . '(?:static)|'; } },
) or die "Incorrect usage!\n";

if ($pattern) {
   $pattern =~ s/\|*$//;
   $pattern = '\b(?:' . $pattern;
   $pattern = $pattern . ')\b';
} else {
   $pattern = '\b(?:(?:__init)|(?:__exit)|(?:inline)|(?:static))\b';
}

undef $/;

my $file = <>;

$file =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//([^\\]|[^\n][\n]?)*?\n|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $3 ? $3 : ""#gse;

#define
#elseif
#ifdef
#ifndef
#if
#
#line
#endif
#else
#include
#undef
#
#^[ \t]*sdfasdfsad()[ \t]*$
#
#error
#warning

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:error|warning)
   [ \t]*
   \"
      (
         (?>[^"\\\n]+)
         |
         \\"
         |
         \\\n
      )*
   \"
   [ \t]*$
//gmx;

$file =~ s/
   ^
   [ \t]*
   (?!if|for|return|while)
   \w+
   [ \t]*
   (?<margs>
      \(
         (?:
            (?>[^\(\)\n\{\;\}]+)
            |
            (?&margs)
         )+
      \)
      [ \t]*
      \n
   )(?!\s*[\{\\;])
//gmx;

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      e(?:lse|ndif)
      |
      line
      |
      include
      |
      undef
   )
   .*
   $
//gmx;

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      define
      |
      elif
      |
      ifn?(?:def)?
   )
   [ \t]+
   (?<mbody>
      .*(?=\\\n)
      \\\n
      (?&mbody)?
   )?
   .+
   $
//gmx;

my @exported = $file =~ m/EXPORT_SYMBOL(?:_GPL(?:_FUTURE)?)?\s*\(\s*(\w+)\s*\)\s*;/gm;

my $status;
$status = 1;

my $name;
foreach $name ( @exported ) {
   if ( $file =~
      m/
      (?<fdecl>
         (?<decl>
            [\w \t\s\\\*\(\)\,]*
            $pattern
            [\w \t\s\\\*\(\)\,]+
         )
         (?>
            \b$name        # function name
            \s*                  # spaces between name and arguments
            (?<fargs>
               \(
                (?:
                   (?>[^\(\)]+)
                   |
                   (?&fargs)
                )+
               \)
            )
         )
      )
      \s*                  # spaces between arguments and function body
      (?:
         (?:
            (?:__(?:acquires|releases|attribute__)\s*(?<margs>\((?:(?>[^\(\)]+)|(?&margs))+\)))
            |
            __attribute_const__
            |
            CONSTF
            |
            \\
         )\s*
      )*
      (?>
         (?<fbody>                    # function body group
            \{                # begin of function body
            (?:               # recursive pattern
               (?>[^\{\}]+)
               |
               (?&fbody)
            )*
            \}                # end of function body
         )
      )
      /gmx
   ) {
      $status = 0;
      
      my $decl = $+{fdecl};
      
      $decl =~ s/\n/ /g;
      $decl =~ s/^[ \t]*$//g;
      $decl =~ s/^[ \t]*//g;
      $decl =~ s/\s{2,}/ /g;
      $decl =~ s/\*\s+/*/g;
      $decl =~ s/\b\*/ */g;
      $decl =~ s/\*\s+\*/**/g;
      $decl =~ s/(\w+)\s+\(/$1(/g;
      
      $decl =~ s/(?<args>(?<br>\((?:(?>[^\(\)]+)|(?&br))+\)))\s*$//;
      my $args = $+{args};
      $args =~ s/^\s*\(//;
      $args =~ s/\)\s*$//;
      $args =~ m/^\s*(?<arg>[^,]+)/;
      my $first_arg = $+{arg};
      if ( $decl =~ m/\(\s*\Q$first_arg\E\s*[,)]/p ) {
         #my $expr;
         #foreach $expr (1..$#-) {
         #   print "Match at position ($-[$expr],$+[$expr])\n";
         #}
         my $first_func = ${^PREMATCH};
         $first_func =~ s/\(\s*$//g;
         $decl =~ s/\Q$first_func\E\s*(?<br>\((?:(?>[^\(\)]+)|(?&br))+\))\s*//;
         
         $first_func =~ m/(?<first_func_name>\w+)\s*$/p;
         
         # return argumenst equality check
         if ( substr(${^PREMATCH}, 0, $-[0]) eq substr($decl, 0, $-[0])) {
            say $first_func;
         }
      }
      
      say $decl . "( " . $args . " )";
#   } else {
#      say STDERR $name;
   }
   pos($file) = 0;
}

exit $status

