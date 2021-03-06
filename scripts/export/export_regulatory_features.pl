#!/usr/bin/env perl

use strict;
use File::Spec;
use Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::DBConnection;
use Getopt::Long;

my $epigenome_name;
my $regulation_database_url;
my $ontology_database_url;
my $ftp_base_dir;

GetOptions (
   'epigenome_name=s'          => \$epigenome_name,
   'regulation_database_url=s' => \$regulation_database_url,
   'ontology_database_url=s'   => \$ontology_database_url,
   'ftp_base_dir=s'            => \$ftp_base_dir,
);

my $ontology_dbc   = Bio::EnsEMBL::Hive::DBSQL::DBConnection->new(-url => $ontology_database_url);
my $regulation_dbc = Bio::EnsEMBL::Hive::DBSQL::DBConnection->new(-url => $regulation_database_url);

use Bio::EnsEMBL::Utils::Logger;
my $logger = Bio::EnsEMBL::Utils::Logger->new();

use Bio::EnsEMBL::DBSQL::OntologyTermAdaptor;
my $ontology_term_adaptor = Bio::EnsEMBL::DBSQL::OntologyTermAdaptor->new(
  Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -dbconn  => $ontology_dbc,
  )
);

my $funcgen_db_adaptor = Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor->new(
    -dbconn  => $regulation_dbc,
);

my $epigenome_adaptor = $funcgen_db_adaptor->get_EpigenomeAdaptor;
my $epigenome = $epigenome_adaptor->fetch_by_name($epigenome_name);

if (! defined $epigenome) {
  die("Can't find epigenome with name " . $epigenome_name);
}

$logger->info("Exporting regulatory features for " . $epigenome->display_label ."\n");

my $output_file = File::Spec->catfile(
  $ftp_base_dir,
  create_filename_from_epigenome($epigenome)
);
$logger->info("The features will be written to " . $output_file ."\n");

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
  -DB_CONNECTION => $regulation_dbc
);

my $number_of_regulatory_features = $helper->execute_simple(
  -SQL      => 'select count(stable_id) from regulatory_feature join regulatory_build using (regulatory_build_id) join regulatory_activity using (regulatory_feature_id) where is_current=1 and epigenome_id=?',
  -PARAMS => [ $epigenome->dbID ],
)->[0];

$logger->info("There are " . $number_of_regulatory_features ." regulatory features\n");

if ($number_of_regulatory_features == 0) {
  $logger->info("Since there are not regulatory features for this epigenome, this program will exit.\n");
  exit;
}

use File::Basename;
my $ftp_dir = dirname($output_file);

use File::Path qw(make_path);
make_path($ftp_dir);

use IO::File;
my $output_fh = IO::File->new(">$output_file");

use Bio::EnsEMBL::Utils::IO::GFFSerializer;
my $serializer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new(
  $ontology_term_adaptor,
  $output_fh
);

my $regulatory_feature_adaptor = $funcgen_db_adaptor->get_RegulatoryFeatureAdaptor;

my $progressbar_id = $logger->init_progress($number_of_regulatory_features, 100);
my $i=0;

my $last_id = 0;
my $exported_something = 1;
my $batch_size = 10000;

while ($exported_something) {

  $exported_something = undef;

  $helper->execute_no_return(
    -SQL      => 'select regulatory_feature_id from regulatory_feature join regulatory_build using (regulatory_build_id) where is_current=1 and regulatory_feature_id > ? order by regulatory_feature_id limit ?',
    -PARAMS => [ $last_id, $batch_size ],
    -CALLBACK => sub {
      my @row  = @{ shift @_ };
      my $dbid = $row[0];
      my $regulatory_feature  = $regulatory_feature_adaptor->fetch_by_dbID($dbid);
      my $regulatory_activity = $regulatory_feature->regulatory_activity_for_epigenome($epigenome);

      if ($regulatory_activity) {
	$serializer->print_feature($regulatory_activity);
      }
      # This prevents memory leaks.
      undef %$regulatory_feature;

      $exported_something = 1;
      $last_id = $dbid;
      return;
    },
  );
  $i+=$batch_size;
  $logger->log_progressbar($progressbar_id, $i);
}

$logger->info("Export done.\n");
$logger->info("Gzipping $output_file\n");

use Bio::EnsEMBL::Funcgen::Utils::EFGUtils qw( run_system_cmd );
run_system_cmd("gzip $output_file");

sub create_filename_from_epigenome {
  my $epigenome = shift;
  return
    File::Spec->catfile(
      &gff_output_directory,
      $epigenome->production_name
      . '.gff'
    )
}

sub gff_output_directory {
  return 'regulatory_features'
}
