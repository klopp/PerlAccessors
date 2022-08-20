package Accessors::Base;

use strict;
use warnings;

use Array::Utils qw/intersect array_minus/;
use Carp qw/cluck confess carp croak/;
use Const::Fast;
use Scalar::Util qw/blessed/;

const my $ACCESS_DENIED => 'Access denied to field "%s"';
const my $METHOD_EXISTS => 'Method "%s" already exists';
const my @PKG_METHODS   => qw/can isa new VERSION DESTROY AUTOLOAD CHECK BEGIN END/;

use vars qw/$PROP_METHOD $PRIVATE_DATA %OPT/;
$PROP_METHOD  = 'property';
$PRIVATE_DATA = 'PRIVATE_DATA';

use base qw/Exporter/;

our @EXPORT = qw/$PROP_METHOD $PRIVATE_DATA _eaccess _emethod/;

use Modern::Perl;
use DDP;

#------------------------------------------------------------------------------
sub _eaccess
{
    my ( $self, $field ) = @_;
    if ( $self->{$PRIVATE_DATA}->{OPT}->{access} && Carp->can( $self->{$PRIVATE_DATA}->{OPT}->{access} ) ) {
        no strict 'refs';
        $self->{$PRIVATE_DATA}->{OPT}->{access}->( sprintf $ACCESS_DENIED, $field );
    }
    return;
}

#------------------------------------------------------------------------------
sub _emethod
{
    my ( $self, $method ) = @_;
    if ( $self->{$PRIVATE_DATA}->{OPT}->{method} && Carp->can( $self->{$PRIVATE_DATA}->{OPT}->{method} ) ) {
        no strict 'refs';
        $self->{$PRIVATE_DATA}->{OPT}->{method}->( sprintf $METHOD_EXISTS, $method );
    }
    return;
}

#------------------------------------------------------------------------------
sub _import
{
    my $self = shift;

    my (@exports);

    # temporary storage:
    %OPT = ();

    for (@_) {
        if ( ref $_ eq 'HASH' ) {
            %OPT = ( %OPT, %{$_} );
        }
        else {
            push @exports, $_;
        }
    }

    @_ = ( $self, @exports );
    goto &Exporter::import;
}

#------------------------------------------------------------------------------
sub _set_internal_data
{
    my ( $self, $params ) = @_;

    confess sprintf( '%s can deal with blessed references only', __PACKAGE__ )
        unless blessed $self;

    confess
        sprintf( "Can not set private data, field '%s' already exists in %s.\nUse \$%s::%s = 'unique name' before.\n",
        $PRIVATE_DATA, __PACKAGE__, __PACKAGE__, $PRIVATE_DATA )
        if exists $self->{$PRIVATE_DATA};

    if ($params) {
        confess sprintf( '%s can receive option as hash reference only', __PACKAGE__ )
            if ref $params ne 'HASH';
        %OPT = ( %OPT, %{$params} );
    }
    my @fields = keys %{$self};
    @fields = intersect( @fields, @{ $OPT{include} } ) if $OPT{include};
    @fields = array_minus( @fields, @{ $OPT{exclude} } )
        if $OPT{exclude};
    @fields = array_minus( @fields, @PKG_METHODS );
    $self->{$PRIVATE_DATA}->{FIELDS} = [@fields];
    %{ $self->{$PRIVATE_DATA}->{OPT} } = %OPT;
    return $self;
}

#------------------------------------------------------------------------------
1;

=head1 NAME

Accessors::Base

=head1 DESCRIPTION

Base class for Accessors::Weak and Accessors::Strict
 
