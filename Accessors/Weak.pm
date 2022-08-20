package Accessors::Weak;

use strict;
use warnings;

use vars qw/$VERSION/;
$VERSION = '2.001';

use List::MoreUtils qw/any/;
our @EXPORT_OK = qw/create_accessors create_property create_get_set/;

use Accessors::Base;

#------------------------------------------------------------------------------
sub import
{
    goto &Accessors::Base::_import;
}

#------------------------------------------------------------------------------
sub create_accessors
{
    my ( $self, $opt ) = @_;
    my $package = ref $self;
    Accessors::Base::_set_internal_data( $self, $opt );

    for my $field (@FIELDS) {
        if ( !$self->can($field) ) {
            no strict 'refs';
            *{"$package\::$field"} = sub {
                my $self = shift;
                if (@_) {
                    my $value = shift;
                    if ( $OPT{validate}->{$field} ) {
                        return unless $OPT{validate}->{$field}->($value);
                    }
                    $self->{$field} = $value;
                }
                return $self->{$field};
            }
        }
        else {
            _emethod("$package\::$field");
        }
    }
    return $self;
}

#------------------------------------------------------------------------------
sub create_property
{
    my ( $self, $opt ) = @_;
    my $package = ref $self;
    Accessors::Base::_set_internal_data( $self, $opt );
    my $property = $OPT{property} || $PROP_METHOD;

    if ( !$self->can($property) ) {
        no strict 'refs';
        *{"$package\::$property"} = sub {
            my ( $self, $field ) = ( shift, shift );
            if ( any { $field eq $_ } @FIELDS ) {
                if (@_) {
                    my $value = shift;
                    if ( $OPT{validate}->{$field} ) {
                        return unless $OPT{validate}->{$field}->($value);
                    }
                    $self->{$field} = $value;
                }
                return $self->{$field};
            }
            else {
                return _eaccess($field);
            }
        }
    }
    else {
        _emethod($property);
    }
    return $self;
}

#------------------------------------------------------------------------------
sub create_get_set
{
    my ( $self, $opt ) = @_;
    my $package = ref $self;
    Accessors::Base::_set_internal_data( $self, $opt );

    for my $field (@FIELDS) {
        if ( !$self->can( 'get_' . $field ) ) {
            no strict 'refs';
            *{"$package\::get_$field"} = sub {
                my ($self) = @_;
                return $self->{$field};
            }
        }
        else {
            _emethod("$package\::get_$field");
        }
        if ( !$self->can( 'set_' . $field ) ) {
            no strict 'refs';
            *{"$package\::set_$field"} = sub {
                my ( $self, $value ) = @_;
                if ( $OPT{validate}->{$field} ) {
                    return unless $OPT{validate}->{$field}->($value);
                }
                $self->{$field} = $value;
                return $self->{$field};
            }
        }
        else {
            _emethod("$package\::set_$field");
        }
    }
    return $self;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Accessors::Weak 

=head1 SYNOPSIS

=over

=item Accessors for whole package

    package AClass;
    use base q/Accessors::Weak/;
    sub new
    {
        my ($class) = @_;
        my $self = bless {
            array  => [1],
            hash   => { 2 => 3 },
            scalar => 'scalar value',
        }, $class;

        return $self->create_accessors;
        # or
        # return $self->create_property;
        # or
        # return $self->create_get_set;
    }

=item Accessors for single object

    use Accessors::Strict qw/create_accessors create_property create_get_set/;
    my $object = MyClass->new;
    $object = create_accessors($object);
    # OR
    # $object = create_property($object);
    # OR
    # $object = create_get_set($object);

=back

=head1 DESCRIPTION

Create methods to get/set package fields.

=head1 CUSTOMIZATION

All methods take an optional argument: a hash reference with additional parameters. For example:

    create_property($object, { exclude => [ 'index' ], access => 'carp', property => 'prop' } );

=over

=item include => [ name1, name2, ... ]

List of field names for which to create accessors. By default, accessors are created for all fields.

=item exclude => [ name1, name2, ... ]

List of field names for which you do not need to create accessors. This parameter is processed after C<include>.

=item property => name

The name of the method that will be created when C<create_property()> is called. The default is C<"property">.

=item validate => { field => coderef, ... }

List of validators for set values. Functions must return undef if validation fails. In this case, the field value is not set and the accessor returns undef. For example:

    $books->create_accessors( {
        validate => {
            author => sub
            {
                my ($author) = @_;
                if( length $author < 3 ) {
                    carp "Author name is too short";
                    return;
                }
                1;
            }
        },
    });


=item access => class

How to handle an access violation (see the C<include> and C<exclude> lists). Can be C<"carp">, C<"cluck">, C<"croak"> or C<"confess"> (L<Carp> module methods). Any other value will skip processing (default behavior).

=item method => class

When an accessor is created, if a method with the same name is found in a package or object, this handler will be called. Values are similar to the C<access> parameter.

=back

=head2 Setting custom properties on module load.

    use Accessors::Strict qw/create_accessors/, { access => croak };

=head2 Setting custom properties on the methods call.

    $object->create_accessors( $object, { exclude => [ 'index' ] } );

=head1 SUBROUTINES/METHODS

=over

=item create_accessors( I<$options> )

Creates methods to get and set the values of fields with the same name. For example, the following method would be created for the C<author> field:

    sub author
    {
        my $self = shift;
        $self->{author} = shift if @_;
        return $self->{author};
    }

In case of an access violation (see the C<include> and C<exclude> parameters), the C<access> parameter is processed.

=item create_property( I<$options> )

Creates a method named C<$options->{property}> (default C<"property">) to access fields:

    sub property
    {
        my ( $self, $field ) = (shift, shift);
        $self->{$field} = shift if @_;
        return $self->{$field};
    }

In case of an access violation (see the C<include> and C<exclude> parameters), the C<access> parameter is processed.

=item create_get_set( I<$options> )

Creates a couple of methods for getting and setting field values:
    
    sub get_author
    {
        # [...]
    }
    sub set_author
    {
        # [...]
    }

=back

=head1 DEPENDENCIES 

=over

=item L<Array::Utils>

=item L<Carp>

=item L<Const::Fast>
 
=item L<List::MoreUtils>

=item L<Scalar::Util>

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 Vsevolod Lutovinov.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. The full text of this license can be found in 
the LICENSE file included with this module.

=head1 AUTHOR

Contact the author at kloppspb@bk.ru

