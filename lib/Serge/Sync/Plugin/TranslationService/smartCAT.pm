package Serge::Sync::Plugin::TranslationService::smartCAT;
use parent Serge::Sync::Plugin::Base::TranslationService, Serge::Interface::SysCmdRunner;

use strict;

use Serge::Util qw(subst_macros);

sub name {
    return 'SmartCAT translation server (http://smartcat.io/) .po synchronization plugin';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->{optimizations} = 1; # set to undef to disable optimizations

    $self->merge_schema({
        project_id     => 'STRING',
        manage_pl_path => 'STRING',
        token_id       => 'STRING',
        token          => 'STRING',
    });
}

sub validate_data {
    my ($self) = @_;

    $self->SUPER::validate_data;

    $self->{data}->{project_id} = subst_macros($self->{data}->{project_id});
    $self->{data}->{manage_pl_path} = subst_macros($self->{data}->{manage_pl_path});
    $self->{data}->{token_id} = subst_macros($self->{data}->{token_id});
    $self->{data}->{token} = subst_macros($self->{data}->{token});

    die "'project_id' not defined" unless defined $self->{data}->{project_id};
    die "'manage_pl_path' not defined" unless defined $self->{data}->{manage_pl_path};
    die "'manage_pl_path', which is set to '$self->{data}->{manage_pl_path}', does not point to a valid file.\n" unless -f $self->{data}->{manage_pl_path};
    die "'token_id' not defined" unless defined $self->{data}->{token_id};
    die "'token' not defined" unless defined $self->{data}->{token};
}

sub run_manage_pl {
    my ($self, $action, $langs, $capture) = @_;

    my $command = $action.' --project='.$self->{data}->{project_id};

    if ($langs) {
        foreach my $lang (sort @$langs) {
            $lang =~ s/-(\w+)$/'_'.uc($1)/e; # convert e.g. 'pt-br' to 'pt_BR'
            $command .= " --language=$lang";
        }
    }

    $command .= " --token_id=" + $self->{data}->{token_id};
    $command .= " --token=" + $self->{data}->{token};

    $command = $self->{data}->{manage_pl_path}.' '.$command;
    print "Running '$command'...\n";
    return $self->run_cmd($command, $capture);
}

sub pull_ts {
    my ($self, $langs) = @_;

    my $force = $self->{optimizations} ? '' : ' --overwrite';

    return $self->run_manage_pl('sync_stores --skip-missing'.$force, $langs);
}

sub push_ts {
    my ($self, $langs) = @_;

    my $force = $self->{optimizations} ? '' : ' --force';

    $self->run_manage_pl('update_stores'.$force, $langs);
}

1;