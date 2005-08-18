use inc::Module::Install;

name          ( 'Perl-BestPractice'           );
abstract      ( 'Perl Best Practices, the (unofficial) companiion module' );
author        ( 'Adam Kennedyn <cpan@ali.as>' );
version_from  ( 'lib/Perl/BestPractice.pm'    );
license       ( 'perl'                        );
requires      ( 'perl'             => '5.005' );
requires      ( 'Carp'             => 0       );
requires      ( 'Params::Util'     => 0       );
requires      ( 'PPI'              => '1.003' );
build_requires( 'File::Spec'       => '0.80'  );
build_requires( 'Test::More'       => '0.47'  );

auto_install();

&WriteAll;
