package Dist::Zilla::Plugin::Comment;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub __comment_lines {
    local $_ = shift;
    s/^/## //g;
    $_;
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    my $modified;

    $modified++ if
        $content =~ s/^(=for [ ] BEGIN_COMMENT$)
                      (\n[ \t]*)+
                      (.+?)
                      (\n[ \t]*)+
                      ^(=for [ ] END_COMMENT$)/$1 . $2 . __comment_lines($3) . $4 . $5/egmsx;

    $modified++ if
        $content =~ s/^(\# [ ] BEGIN_COMMENT$)
                      (.+?)
                      ^(\# [ ] END_COMMENT$)/$1 . __comment_lines($2) . $3/egmsx;

    $modified++ if
        $content =~ s/^(.+)(# COMMENT$)/__comment_lines($1) . $2/egm;

    if ($modified) {
        $self->log(["commented block(s)/line(s) in '%s'", $file]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Comment-out lines or blocks of lines

=for Pod::Coverage .+

=head1 SYNOPSIS

In C<dist.ini>:

 [Comment]

In C<lib/Foo.pm>:

 ...

 do_something(); # COMMENT

 # BEGIN_COMMENT
 one();
 two();
 three();
 # END_COMMENT

 =pod

 =for BEGIN_COMMENT

 blah
 blah
 blah

 =for END_COMMENT

 ...

After build, C<lib/Foo.pm> will become:

 ...

 ## do_something(); # COMMENT

 # BEGIN_COMMENT
 ## one();
 ## two();
 ## three();
 # END_COMMENT

 =pod

 =for BEGIN_COMMENT

 ## blah
 ## blah
 ## blah

 =for END_COMMENT

 ...



=head1 DESCRIPTION

This plugin finds lines that end with C<# COMMENT>, or blocks of lines delimited
by C<# BEGIN COMMENT> ... C<# END_COMMENT> or C<=for BEGIN_COMMENT> ... C<=end
END_COMMENT> and comment them out.

This can be used, e.g. to do stuffs only when the source file is not the
dzil-built version, usually for testing.


=head1 SEE ALSO

You can use this plugin in conjunction with L<Dist::Zilla::Plugin::InsertBlock>.
DZP:InsertBlock can insert lines that will only be available in the dzil-built
version. While for the raw version, you can use DZP:Comment plugin to make lines
that will be commented-out in the dzil-built version.
