package Accessors::Strict;

use strict;
use warnings;

use vars qw/$VERSION $CLASS_SUFFIX/;
$VERSION      = '2.001';
$CLASS_SUFFIX = 'DEADBEEF';

use List::MoreUtils qw/any/;
our @EXPORT_OK = qw/create_accessors create_property create_get_set/;

use Accessors::Base;
use DDP;

#------------------------------------------------------------------------------
sub import
{
    goto &Accessors::Base::_import;
}

#------------------------------------------------------------------------------
sub _set_internal_data
{
    my ( $self, $params ) = @_;

    Accessors::Base::_set_internal_data( $self, $params );

    my $package = ref $self;
    $self->{$PRIVATE_DATA}->{KEYS} = {} unless $self->{$PRIVATE_DATA}->{KEYS};
    $self->{$PRIVATE_DATA}->{KEYS}->{$_} = $self->{$_} for @{ $self->{$PRIVATE_DATA}->{FIELDS} };

    my $newclass = $package . '::' . $CLASS_SUFFIX++;
    no strict 'refs';
    @{"$newclass\::ISA"} = ($package);
    return $newclass;
}

#------------------------------------------------------------------------------
sub _create_access
{
    my ($self) = @_;

    my $access = sub {
        my $field = shift;

        if ( any { $field eq $_ } @{ $self->{$PRIVATE_DATA}->{FIELDS} } ) {
            if (@_) {
                my $value = shift;
                if ( $self->{$PRIVATE_DATA}->{OPT}->{validate}->{$field} ) {
                    return unless $self->{$PRIVATE_DATA}->{OPT}->{validate}->{$field}->($value);
                }
                $self->{$PRIVATE_DATA}->{KEYS}->{$field} = $value;
            }
            return $self->{$PRIVATE_DATA}->{KEYS}->{$field};
        }
        else {
            return _eaccess( $self, $field );
        }
    };
    return $access;
}

#------------------------------------------------------------------------------
sub create_accessors
{
    my ( $self, $params ) = @_;
    my $newclass = _set_internal_data( $self, $params );
    my $access   = _create_access($self);

    for my $field ( @{ $self->{$PRIVATE_DATA}->{FIELDS} } ) {
        if ( !$self->can($field) ) {
            no strict 'refs';
            *{"$newclass\::$field"} = sub {
                shift;
                return $access->( $field, @_ );
            }
        }
        else {
            _emethod( $self, ( ref $self ) . '::' . $field );
        }
    }
    return bless $access, $newclass;
}

#------------------------------------------------------------------------------
sub create_property
{
    my ( $self, $params ) = @_;
    my $newclass = _set_internal_data( $self, $params );
    my $property = $self->{$PRIVATE_DATA}->{OPT}->{property} || $PROP_METHOD;
    my $access   = _create_access($self);

    if ( !$self->can($property) ) {
        no strict 'refs';
        *{"$newclass\::$property"} = sub {
            shift;
            return $access->(@_);
        }
    }
    else {
        _emethod( $self, $property );
    }
    return bless $access, $newclass;
}

#------------------------------------------------------------------------------
sub create_get_set
{
    my ( $self, $params ) = @_;
    my $newclass = _set_internal_data( $self, $params );
    my $access   = _create_access($self);

    for my $field ( @{ $self->{$PRIVATE_DATA}->{FIELDS} } ) {
        if ( !$self->can( 'get_' . $field ) ) {
            no strict 'refs';
            *{"$newclass\::get_$field"} = sub {
                shift;
                return $access->($field);
            }
        }
        else {
            _emethod( $self, ( ref $self ) . '::get_' . $field );
        }
        if ( !$self->can( 'set_' . $field ) ) {
            no strict 'refs';
            *{"$newclass\::set_$field"} = sub {
                shift;
                return $access->( $field, shift );
            }
        }
        else {
            _emethod( $self, ( ref $self ) . '::set_' . $field );
        }
    }
    return bless $access, $newclass;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Accessors::Strict

=head1 DESCRIPTION

See Accessors::Weak POD.
 

