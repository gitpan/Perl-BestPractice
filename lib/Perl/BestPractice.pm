package Perl::BestPractice;

=pod

=head1 NAME

Perl::BestPractice - Perl Best Practices, the (unofficial) companion module

=head1 SYNOPSIS

  use PPI;
  use Perl::BestPractice 'PBP';
  
  # Locate bad list transformations in a document
  my $Document = PPI::Document->new( 'Module.pm' );
  my $found = PBP->find('list_transformation')->in( $Document );
  
  # We're not having that sort of things around HERE!
  if ( $found ) {
  	my $name = PBP->name('list_transformation');
  	die "Document failed Perl Best Practice '$name'\n";
  }

=head1 STATUS

At this time, C<Perl::BestPractice> is considered entirely experimental.

Function, structure and APIs are subject to change.

If you wish to use this for an editor project or some other task, please
consider joining the parseperl-discuss@ mailing list from the L<PPI>
SourceForge website.

=head1 DESCRIPTION

C<Perl::BestPractice> is the (for now unofficial) companion module to the
O'Reilly "Perl Best Practices" by Damian Conway.

Using various bits of L<PPI> magic, it provides functionality to
automatically locate (and in some cases repair) issues raised by the
book.

=head2 Using Perl::BestPractice

You don't yet. There's some interesting tools coming for you to play with
in the next version.

=head1 METHODS

=begin testing SETUP 5

use Perl::BestPractice 'PBP';

is( PBP, 'Perl::BestPractice' );
can_ok( PBP, 'name'        );
can_ok( PBP, 'description' );
can_ok( PBP, 'wanted'      );
can_ok( PBP, 'find'        );

sub new_ok {
	my $class = shift;
	my $self  = $class->new(@_);
	isa_ok( $self, $class );
	$self;
}

sub practise_ok {
	my $name = shift;
	ok( PBP->name($name),        "Practice '$name' exists in %NAME"        );
	ok( PBP->description($name), "Practice '$name' exists in %DESCRIPTION" );
	ok( PBP->wanted($name),      "Practice '$name' exists in %WANTED"      );
	ok( PBP->find($name),        "Practice returns true for ->find"        );
}

=end testing

=cut

use strict;
use Carp         ();
use Params::Util qw{_IDENTIFIER _SCALAR _CODE};
use PPI          ();
use PPI::Find    ();
use base 'Exporter';
use constant PBP => 'Perl::BestPractice';

use vars qw{$VERSION @EXPORT_OK};
use vars qw{%NAME %DESCRIPTION %WANTED};
BEGIN {
	$VERSION     = '0.01';
	@EXPORT_OK   = 'PBP';

	# Practice data storage
	%NAME        = ();
	%DESCRIPTION = ();
	%WANTED      = ();
}





#####################################################################
# Register a PBP

sub _register_practise {
	my $class  = shift;
	my $ident  = _IDENTIFIER(shift) or Carp::croak(
		"No or invalid practise name"
		);

	# Set up the basics
	my %params = @_;
	$NAME{$ident} = $params{name}
		or Carp::croak("No PBP name provided to register_practise");
	$DESCRIPTION{$ident} = $params{description}
		or Carp::croak("No PBP description provided to register_practise");
	$WANTED{$ident} = _CODE($params{wanted})
		or Carp::croak("No PBP wanted function provided to register_practise");

	1;
}





#####################################################################
# Perl::BestPractice API

=pod

=head2 name $identifier

The C<name> static method takes a PBP identifier and returns the English name
of the practise as used in the PBP book as a string.

=cut

sub name { $NAME{$_[-1]} }

=pod

=head2 description $identifier

The C<description> static method takes a PBP identifier and returns the
description of the practise as defined in the PBP book as a string.

=cut

sub description { $DESCRIPTION{$_[-1]} }

=pod

=head2 wanted $identifier

The C<wanted> static method takes a PBP identifier and returns a PPI
C<&wanted> function for that practise.

=cut

sub wanted { $WANTED{$_[-1]} }

=pod

=head2 find $identifier

The C<find> method creates a L<PPI::Find> object that can be used to search
for the practise in a L<PPI::Document> and if needed iterate through the
found elements.

Returns a L<PPI::Find> object, or return C<undef> if the identifier does
not exist.

=cut

sub find {
	my $class  = shift;
	my $wanted = $WANTED{$_[0]} or return undef;
	PPI::Find->new($wanted);
}





#####################################################################
# Practices

=pod

=head1 BEST PRACTISES

=cut

###------------------------------------------------------------------

=pod

=head2 subroutines_and_variables - "Code Layout: Subroutines and Variables"

C<subroutines_and_variables> is the identifier for the practise
in "Code Layout: Subroutines and Variables", which is fully stated as the
following (with examples).

  "Don't separate subroutine or variable names from the following
   opening bracket"
  
  # Bad
  get_candidates ($market);
  $candidates [$i]
      = $incumbent {$candidates [$i] {region}};
  
  # Good
  get_candidates($market);
  $candidates[$i]
      = $incumbent{$candidates[$i]{region}};

Supported methods: name, description, wanted, find

=begin testing subroutines_and_variables 4

practise_ok('subroutines_and_variables');

=end testing

=cut

PBP->_register_practise( 'subroutines_and_variables',
	name        => 'Subroutines and Variables',
	description => "Don't separate subroutine or variable names from"
		. " the following opening bracket",
	wanted      => \&_wanted_subroutines_and_variables,
	page        => [ 12 ],
);

sub _wanted_subroutines_and_variables {
	my $Element = $_[1];

	# Limit this to one space gaps
	$Element->isa('PPI::Token::Whitespace') or return '';
	$Element->content eq ' '                or return '';

	# We'll need the tokens on either side
	my $left  = $Element->previous_sibling  or return '';
	my $right = $Element->next_sibling      or return '';

	if ( $right->isa('PPI::Structure::Subscript') ) {
		# $foo{bar} etc
		return 1 if $left->isa('PPI::Token::Symbol');

		# $foo->{bar}
		return 1 if $left->content eq '->';
	}

	# Add more things here later
	'';
}

###------------------------------------------------------------------

=pod

=head2 empty_strings - "Values and Expressions: Empty Strings"

C<empty_strings> is the identifier for the practise in "Values and
Expressions: Empty Strings", which is fully stated as the following
(with examples).

  "Don't use "" or '' for an empty string"
  
  # Bad
  $error_msg = '';
  
  # Good
  $error_msg = q{}; # Empty string

Supported methods: name, description, wanted, find

=begin testing empty_string 8

practise_ok('empty_string');

my $code = <<'END_PERL';
1;
sub foo {
	my $bar = '';     # yes
	$baz = q();       # no
	baz( foo => "" ); # yes
}
END_PERL
my $Document = new_ok( 'PPI::Document', \$code );
my $found    = $Document->find( PBP->wanted('empty_string') );
is( scalar(@$found), 2,
	'empty_string: Found 2 list transformations' );
is( $Document->schild(1)->schild(2)->schild(0)->schild(3), $found->[0],
	'empty_string: Wanted function returned the expected element (1)' );
is( $Document->schild(1)->schild(2)->schild(2)->schild(1)->schild(0)->schild(2), $found->[1],
	'empty_string: Wanted function returned the expected element (2)' );

=end testing

=cut

PBP->_register_practise( 'empty_string',
	name        => 'Empty Strings',
	description => "Don't use \"\" or '' for an empty string",
	wanted      => \&_wanted_empty_string,
	page        => [ 53 ],
);

sub _wanted_empty_string {
	my $Element = $_[1];
	$Element->isa('PPI::Token::Quote') or return '';
	if ( $Element->isa('PPI::Token::Quote::Single') ) {
		return 1 if $Element->string eq '';
	}
	elsif ( $Element->isa('PPI::Token::Quote::Double') ) {
		return 1 if $Element->string eq '';
	}
	'';
}

###------------------------------------------------------------------

=pod

=head2 leading_zero : "Values and Expressions: Leading Zeros"

C<leading_zero> is the identifier for the practise 
"Values and Expressions: Leading Zeros", which is fully stated as the
following (with examples).

  "Don't pad decimal numbers with leading zeros"
  
  # Bad
  0600
  
  # Good
  oct(600)

Supported methods: name, description, wanted, find

=begin testing leading_zero 8

practise_ok('leading_zero');

my $code = <<'END_PERL';
1;
sub foo {
	my $bar = 010;       # no
	my $foo = oct(10);   # yes
	baz( foo => 00300 ); # yes
}
END_PERL
my $Document = new_ok( 'PPI::Document', \$code );
my $found     = $Document->find( PBP->wanted('leading_zero') );
is( scalar(@$found), 2,
	'leading_zero: Found 2 list transformations' );
is( $Document->schild(1)->schild(2)->schild(0)->schild(3), $found->[0],
	'leading_zero: Wanted function returned the expected element (1)' );
is( $Document->schild(1)->schild(2)->schild(2)->schild(1)->schild(0)->schild(2), $found->[1],
	'leading_zero: Wanted function returned the expected element (2)' );

=end testing

=cut

PBP->_register_practise( 'leading_zero',
	name        => 'Leading Zeros',
	description => "Don't use leading zeros",
	wanted      => \&_wanted_leading_zero,
	page        => [ 53 ],
);

sub _wanted_leading_zero {
	my $Element = $_[1];

	# Find a number with only digits starting with zero
	$Element->isa('PPI::Token::Number') or return '';
	$Element->content =~ /^0\d+$/       or return '';

	1;
}

###------------------------------------------------------------------

=pod

=head2 non_lexical_loop_iterator : "Non-lexical Loop Iterators"

C<non_lexical_loop_iterator> is the identifier for the practise
"Non-lexical Loop Iterators", which is fully stated as the following
(with examples).

  "Don't use non-lexical loop iterators"
  
  # Bad
  for     $foo ( ... ) { ... }
  foreach $foo ( ... ) { ... }
  
  # Good
  foreach my $foo ( ... ) { ... }

Supported methods: name, description, wanted, find

=begin testing non_lexical_loop_iterator 8

practise_ok('non_lexical_loop_iterator');

my $code = <<'END_PERL';
1;
sub foo {
	for $foo ( @list ) {
		$foo++; # This is bad
	}
	foreach my $bar ( @list ) {
		# This is good
	}
	foreach $bar ( @list ) {
		# This is bad
	}
}
END_PERL
my $Document = new_ok( 'PPI::Document', \$code );
my $found     = $Document->find( PBP->wanted('non_lexical_loop_iterator') );
is( scalar(@$found), 2,
	'non_lexical_loop_iterator: Found 1 list transformation' );
is( $Document->schild(1)->schild(2)->schild(0), $found->[0],
	'non_lexical_loop_iterator: Wanted function returned the expected element (1)' );
is( $Document->schild(1)->schild(2)->schild(2), $found->[1],
	'non_lexical_loop_iterator: Wanted function returned the expected element (2)' );

=end testing

=cut

PBP->_register_practise( 'non_lexical_loop_iterator',
	name        => 'Non-lexical Loop Iterators',
	description => "Don't use non-lexical loop iterators",
	wanted      => \&_wanted_non_lexical_loop_iterator,
	page        => [ 108 ],
);

sub _wanted_non_lexical_loop_iterator {
	my $Element = $_[1];

	# A for or foreach control structure...
	$Element->isa('PPI::Statement::Compound') or return '';
	$Element->type eq 'foreach'               or return '';

	# ...where the second child is a scalar symbol
	my $symbol = $Element->schild(1)          or return '';
	$symbol->isa('PPI::Token::Symbol')        or return '';
	$symbol->symbol_type eq '$'               or return '';

	1;
}

###------------------------------------------------------------------

=pod

=head2 list_transformation : "List Transformations"

C<list_transformation> is the identifier for the practise
I<"List Transformations">, which is fully stated as the following
(with examples).

  "Use for instead of map when transforming a list in place"
  
  # Bad
  @list = map { ... } @list;

Supported methods: name, description, wanted, find

=begin testing list_transformation 7

practise_ok('list_transformation');

my $code = <<'END_PERL';
1;
sub foo {
	my @foo = map { $_++ } @bar;
	@baz = map { $_++ } @bar;
	@baz = map { $_++ } @baz;
	return @baz;
}
END_PERL
my $Document = new_ok( 'PPI::Document', \$code );
my $found     = $Document->find( PBP->wanted('list_transformation') );
is( scalar(@$found), 1,
	'list_transformation: Found 1 list transformation' );
is( $Document->schild(1)->schild(2)->schild(2), $found->[0],
	"list_transformation: Wanted function returned the expected element" );

=end testing

=cut

PBP->_register_practise( 'list_transformation',
	name        => 'List Transformations',
	description => 'Use for instead of map when transforming a list in place',
	wanted      => \&_wanted_list_transformation,
	page        => [ 112 ],
);

sub _wanted_list_transformation {
	my $Element = $_[1];

	# Find a statement with 5 or 6 children
	$Element->isa('PPI::Statement')               or return '';
	my @c = $Element->schildren                   or return '';
	scalar(@c) == 5 or scalar(@c) == 6            or return '';
	if ( $c[5] ) {
		$c[5]->content eq ';'                 or return '';
	}	

	# This is an array operation...
	$c[0] and $c[0]->isa('PPI::Token::Symbol')    or return '';
	$c[0]->symbol_type eq '@'                     or return '';

	# ...implemented using map...
	$c[1] and $c[1]->content eq '='               or return '';
	$c[2] and $c[2]->content eq 'map'             or return '';
	$c[3] and $c[3]->isa('PPI::Structure::Block') or return '';

	# ...saving back to the same array
	$c[4] and $c[4]->isa('PPI::Token::Symbol')    or return '';
	$c[0]->content eq $c[4]->content              or return '';

	1;
}

###------------------------------------------------------------------

=pod

The practises that have been implemented so far are described here,
in the rough order lists by both book name and identifier.

It's worth nothing that while the practise name is generally in plural
form, the identifier is normally in singular form.

=head2 do_while_loop : do-while Loops

C<do_while_loop> is the identifier for the practise "do-while Loops",
which is fully stated as the following (with examples).

  "Don't use do...while loops"
  
  # Bad
  do { ... } while ...

Supported methods: name, description, wanted, find

=begin testing do_while_loop 7

practise_ok('do_while_loop');

my $code = <<'END_PERL';
1;
sub foo {
	1;
	do { print "Hello World!\n" } while 1;
}
END_PERL
my $Document = new_ok( 'PPI::Document', \$code );
my $found  = $Document->find( PBP->wanted('do_while_loop') );
is( scalar(@$found), 1,
	'do_while_loop: Found 1 do-while loop' );
is( $Document->schild(1)->schild(2)->schild(1), $found->[0],
	"do_while_loop: Wanted function returned the expected element" );

=end testing

=cut

PBP->_register_practise( 'do_while_loop',
	name        => 'do-while Loops',
	description => "Don't use do...while loops",
	wanted      => \&_wanted_do_while_loop,
	page        => [ 123 ],
);

sub _wanted_do_while_loop {
	my $Element = $_[1];

	# A statement with children...
	$Element->isa('PPI::Statement')               or return '';
	my @c = $Element->schildren                   or return '';

	# ...that is a do-while
	$c[0] and $c[0]->content eq 'do'              or return '';
	$c[1] and $c[1]->isa('PPI::Structure::Block') or return '';
	$c[2] and $c[2]->content eq 'while'           or return '';

	1;
}

1;

=pod

=head1 TO DO

- Decide on a method for proper error handling and implement it

- Implement more... and more... and more... practises

- Provide a way to suggest alternative code, where a solution is clear

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-BestPractice>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PPI>, Damian Conway's I<"Perl Best Practices"> published by O'Reilly

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
