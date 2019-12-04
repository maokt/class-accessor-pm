package Class::Accessor::Fast;
use base 'Class::Accessor';
use strict;
use B 'perlstring';
$Class::Accessor::Fast::VERSION = '0.51';

sub _make_type_check {
    my ($class, $field, $type, $varname) = @_;

    return unless $type;

    $class->_install_typed_constructor($field, $type);

    require Scalar::Util;

    if (ref($type) eq 'CODE') {
        return (
            undef,
            $type,
            sprintf('$check->(%s) or $_[0]->_croak("Value for \'%s\' failed type constraint")', $varname, $field),
        );
    }
    elsif (Scalar::Util::blessed($type)
    and    $type->can('can_be_inlined')
    and    $type->can_be_inlined
    and    $type->can('inline_check')
    and    $type->can('get_message')) {
        return (
            $type,
            undef,
            sprintf('(%s) or $_[0]->_croak($type->get_message(%s))', $type->inline_check($varname), $varname),
        );
    }
    elsif (Scalar::Util::blessed($type)
    and    $type->can('compiled_check')
    and    $type->can('get_message')) {
        my $compiled = $type->compiled_check;
        return (
            $type,
            $compiled,
            sprintf('$check->(%s) or $_[0]->_croak($type->get_message(%s))', $varname, $varname),
        );
    }
    elsif (Scalar::Util::blessed($type)
    and    $type->can('check')
    and    $type->can('get_message')) {
        return (
            $type,
            undef,
            sprintf('$type->check(%s) or $_[0]->_croak($type->get_message(%s))', $varname, $varname),
        );
    }
    else {
        $class->_croak("Could not handle type constraint for field '$field'");
    }
}

sub make_accessor {
    my ($class, $field, $type) = @_;

    if (my ($typeobj, $check, $perlcode) = $class->_make_type_check($field, $type, '$value')) {
        return eval sprintf q{
            sub {
                return $_[0]{%s} if scalar(@_) == 1;
                my $value = scalar(@_) == 2 ? $_[1] : [@_[1..$#_]];
                %s;
                return $_[0]{%s} = $value;
            }
        }, perlstring($field), $perlcode, perlstring($field);
    }

    eval sprintf q{
        sub {
            return $_[0]{%s} if scalar(@_) == 1;
            return $_[0]{%s}  = scalar(@_) == 2 ? $_[1] : [@_[1..$#_]];
        }
    }, map { perlstring($_) } $field, $field;
}

sub make_ro_accessor {
    my($class, $field, $type) = @_;

    $class->_install_typed_constructor($field, $type) if $type;

    eval sprintf q{
        sub {
            return $_[0]{%s} if @_ == 1;
            my $caller = caller;
            $_[0]->_croak(sprintf "'$caller' cannot alter the value of '%%s' on objects of class '%%s'", %s, %s);
        }
    }, map { perlstring($_) } $field, $field, $class;
}

sub make_wo_accessor {
    my($class, $field, $type) = @_;

    if (my ($typeobj, $check, $perlcode) = $class->_make_type_check($field, $type, '$value')) {
        return eval sprintf q{
            sub {
                if (@_ == 1) {
                    my $caller = caller;
                    $_[0]->_croak(sprintf "'$caller' cannot access the value of '%%s' on objects of class '%%s'", %s, %s);
                }
                my $value = scalar(@_) == 2 ? $_[1] : [@_[1..$#_]];
                %s;
                return $_[0]{%s} = $value;
            }
        }, perlstring($field), perlstring($class), $perlcode, perlstring($field);
    }

    eval sprintf q{
        sub {
            if (@_ == 1) {
                my $caller = caller;
                $_[0]->_croak(sprintf "'$caller' cannot access the value of '%%s' on objects of class '%%s'", %s, %s);
            }
            else {
                return $_[0]{%s} = $_[1] if @_ == 2;
                return (shift)->{%s} = \@_;
            }
        }
    }, map { perlstring($_) } $field, $class, $field, $field;
}

1;

__END__

=head1 NAME

Class::Accessor::Fast - Faster, but less expandable, accessors

=head1 SYNOPSIS

  package Foo;
  use base qw(Class::Accessor::Fast);

  # The rest is the same as Class::Accessor but without set() and get().

=head1 DESCRIPTION

This is a faster but less expandable version of Class::Accessor.
Class::Accessor's generated accessors require two method calls to accomplish
their task (one for the accessor, another for get() or set()).
Class::Accessor::Fast eliminates calling set()/get() and does the access itself,
resulting in a somewhat faster accessor.

The downside is that you can't easily alter the behavior of your
accessors, nor can your subclasses.  Of course, should you need this
later, you can always swap out Class::Accessor::Fast for
Class::Accessor.

Read the documentation for Class::Accessor for more info.

=head1 EFFICIENCY

L<Class::Accessor/EFFICIENCY> for an efficiency comparison.

=head1 AUTHORS

Copyright 2017 Marty Pauley <marty+perl@martian.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=head2 ORIGINAL AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Class::Accessor>

=cut
