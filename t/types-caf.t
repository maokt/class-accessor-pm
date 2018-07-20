#!perl
use strict;
use Test::More;

BEGIN {
    if (eval { require Types::Standard }) {
        Types::Standard->import(qw/ -all /);
        plan tests => 3;
    }
    else {
        plan skip_all => "tests require Types::Standard";
    }
}

sub exception (&) {
    my $code = shift;
    local $@ = undef;
    eval { $code->(); 1 } ? return() : return($@);
}

require_ok("Class::Accessor::Fast");

@Foo::ISA = qw(Class::Accessor::Fast);
Foo->mk_accessors([foo => Str], [bar => Int], "baz");

my $e = exception { Foo->new({ foo => [] }) };

like($e, qr/did not pass type constraint "Str"/, 'exception from constructor');

my $obj = Foo->new({ foo => "foo" });
$obj->foo("FOO");

$e = exception { $obj->foo(undef) };

like($e, qr/did not pass type constraint "Str"/, 'exception from setter');
