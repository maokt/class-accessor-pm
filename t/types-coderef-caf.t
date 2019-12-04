#!perl
use strict;
use Test::More tests => 3;

my $Str = sub { defined($_[0]) and not ref($_[0]) };
my $Int = sub { $Str->(@_) and $_[0] =~ /\A-[0-9]+\z/ };

sub exception (&) {
    my $code = shift;
    local $@ = undef;
    eval { $code->(); 1 } ? return() : return($@);
}

require_ok("Class::Accessor::Fast");

@Foo::ISA = qw(Class::Accessor::Fast);
Foo->mk_accessors([foo => $Str], [bar => $Int], "baz");

my $e = exception { Foo->new({ foo => [] }) };

like($e, qr/failed type constraint/, 'exception from constructor');

my $obj = Foo->new({ foo => "foo" });
$obj->foo("FOO");

$e = exception { $obj->foo(undef) };

like($e, qr/failed type constraint/, 'exception from setter');
