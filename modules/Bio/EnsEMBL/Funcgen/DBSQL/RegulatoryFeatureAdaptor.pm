#
# Ensembl module for Bio::EnsEMBL::DBSQL::Funcgen::RegulatoryFeatureAdaptor
#

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.


=head1 NAME

Bio::EnsEMBL::DBSQL::Funcgen::RegulatoryFeatureAdaptor

=head1 SYNOPSIS

 use Bio::EnsEMBL::Registry;
 use Bio::EnsEMBL::Funcgen::RegulatoryFeature;

 my $reg = Bio::EnsEMBL::Registry->load_adaptors_from_db(
   -host    => 'ensembldb.ensembl.org',
   -user    => 'anonymous'
 );
 
 my $regfeat_adaptor = $reg->get_adaptor($species, 'funcgen', 'RegulatoryFeature');
 
 #Fetch MultiCell RegulatoryFeatures
 my @features = @{$regfeat_adaptor->fetch_all_by_Slice($slice)};
 
 #Fetch epigenome specific RegulatoryFeatures
 my @epigenome_features = @{$regfeat_adaptor->fetch_all_by_Slice_Epigenomes($slice, [$epigenome_fset1, $epigenome_fset2])};
 
 #Fetch all epigenome RegulatoryFeatures for a given stable ID
 my @epigenome_features = @{$regfeat_adaptor->fetch_all_by_stable_ID('ENSR00001348194')};

=head1 DESCRIPTION

The RegulatoryFeatureAdaptor is a database adaptor for storing and retrieving
RegulatoryFeature objects. The FeatureSet class provides convenient wrapper
methods to the Slice functionality within this adaptor.

=cut


package Bio::EnsEMBL::Funcgen::DBSQL::RegulatoryFeatureAdaptor;

use strict;
use warnings;
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Funcgen::RegulatoryFeature;
use Data::Dumper;

# DBI sql_types import
use Bio::EnsEMBL::Funcgen::DBSQL::SetFeatureAdaptor;

use base qw(Bio::EnsEMBL::Funcgen::DBSQL::SetFeatureAdaptor);


my %valid_attribute_features = (
  'Bio::EnsEMBL::Funcgen::MotifFeature'     => 'motif',
  'Bio::EnsEMBL::Funcgen::AnnotatedFeature' => 'annotated',
);

=head2 fetch_by_stable_id

  Arg [1]    : String $stable_id - The stable id of the regulatory feature to retrieve
  Arg [2]    : optional - Bio::EnsEMBL::FeatureSet
  Example    : my $rf = $rf_adaptor->fetch_by_stable_id('ENSR00000309301');
  Description: Retrieves a regulatory feature via its stable id.
  Returntype : Bio::EnsEMBL::Funcgen::RegulatoryFeature
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_by_stable_id {
    my $self      = shift;
    my $stable_id = shift;

    my $constraint = "rf.stable_id = ?";
    $self->bind_param_generic_fetch($stable_id, SQL_VARCHAR);
    my ($regulatory_feature) = @{$self->generic_fetch($constraint)};

    return $regulatory_feature;
}

=head2 _true_tables

  Args       : None
  Example    : None
  Description: Returns the names and aliases of the tables to use for queries.
  Returntype : List of listrefs of strings
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _true_tables {
  return (
    [ 'regulatory_feature',  'rf'  ],
    [ 'regulatory_activity', 'rfs' ],
    [ 'regulatory_build',    'rb'  ],
    [ 'regulatory_evidence', 'ra'  ],
  );
}

=head2 _columns

  Args       : None
  Example    : None
  Description: PROTECTED implementation of superclass abstract method.
               Returns a list of columns to use for queries.
  Returntype : List of strings
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _columns {
  my $self = shift;

  return qw(
    rf.regulatory_feature_id
    rf.seq_region_id
    rf.seq_region_start
    rf.seq_region_end
    rf.seq_region_strand
    rf.bound_start_length
    rf.bound_end_length
    rf.feature_type_id
    rfs.epigenome_id
    rf.stable_id
    rfs.activity
    rf.epigenome_count
    ra.attribute_feature_id
    ra.attribute_feature_table
    rfs.regulatory_activity_id
    rb.analysis_id
  );
}

=head2 _left_join

  Args       : None
  Example    : None
  Description: PROTECTED implementation of superclass abstract method.
               Returns an additional table joining constraint to use for
			   queries.
  Returntype : List
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _left_join {
  return (
    ['regulatory_evidence', 'rfs.regulatory_activity_id = ra.regulatory_activity_id'],
    ['regulatory_build',    'rf.regulatory_build_id = rb.regulatory_build_id']
  );
}

sub _fake_multicell_activity {

  my $self = shift;
  my $actual_regulatory_activity = shift;

  my $multicell_regulatory_activity = Bio::EnsEMBL::Funcgen::RegulatoryActivity->new;
  $multicell_regulatory_activity->activity('ACTIVE');
  $multicell_regulatory_activity->epigenome_id(undef);
  $multicell_regulatory_activity->_is_multicell(1);

  my $multicell_regulatory_evidence = Bio::EnsEMBL::Funcgen::RegulatoryEvidence->new;
  $multicell_regulatory_evidence->db($self->db);

  foreach my $current_regulatory_activity (@$actual_regulatory_activity) {
  
    my $regulatory_evidence = $current_regulatory_activity->regulatory_evidence;
  
    $multicell_regulatory_evidence->add_supporting_annotated_feature_id(
      $regulatory_evidence->supporting_annotated_feature_ids
    );
    $multicell_regulatory_evidence->add_supporting_motif_feature_id(
      $regulatory_evidence->supporting_motif_feature_ids
    );
  }
  $multicell_regulatory_activity->regulatory_evidence($multicell_regulatory_evidence);
  return $multicell_regulatory_activity;
}

=head2 _objs_from_sth

  Arg [1]    : DBI statement handle object
  Example    : None
  Description: PROTECTED implementation of superclass abstract method.
               Creates RegulatoryFeature objects from an executed DBI statement
			   handle.
  Returntype : Listref of Bio::EnsEMBL::RegulatoryFeature objects
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _objs_from_sth {
  my ($self, $sth, $mapper, $dest_slice) = @_;
  
  throw('Using a mapper is not supported!') if (defined $mapper);

  #For EFG this has to use a dest_slice from core/dnaDB whether specified or not.
  #So if it not defined then we need to generate one derived from the species_name and schema_build of the feature we're retrieving.
  # This code is ugly because caching is used to improve speed

  my $sa = ($dest_slice) ? $dest_slice->adaptor->db->get_SliceAdaptor() : $self->db->get_SliceAdaptor();

  #Some of this in now probably overkill as we'll always be using the DNADB as the slice DB
  #Hence it should always be on the same coord system
  my $ft_adaptor = $self->db->get_FeatureTypeAdaptor();
#   my $fset_adaptor = $self->db->get_FeatureSetAdaptor();
  my $analysis_adaptor = $self->db->get_AnalysisAdaptor();
  my (@feature_from_sth, $seq_region_id);
  my (%fset_hash, %slice_hash, %sr_name_hash, %sr_cs_hash, %ftype_hash);

  my (
    $sth_fetched_dbID,
    $sth_fetched_efg_seq_region_id,
    $sth_fetched_seq_region_start,
    $sth_fetched_seq_region_end,
    $sth_fetched_seq_region_strand,
    $sth_fetched_bound_start_length,
    $sth_fetched_bound_end_length,
    $sth_fetched_feature_type_id,
    $sth_fetched_epigenome_id,
    $sth_fetched_stable_id,
    $sth_fetched_attr_id,
    $sth_fetched_attr_type,
    $sth_fetched_bin_string,
    $sth_fetched_activity,
    $sth_fetched_epigenome_count,
    $sth_fetched_regulatory_feature_epigenome_id,
    $sth_fetched_analysis_id
  );

  $sth->bind_columns (
    \$sth_fetched_dbID,
    \$sth_fetched_efg_seq_region_id,
    \$sth_fetched_seq_region_start,
    \$sth_fetched_seq_region_end,
    \$sth_fetched_seq_region_strand,
    \$sth_fetched_bound_start_length,
    \$sth_fetched_bound_end_length,
    \$sth_fetched_feature_type_id,
    \$sth_fetched_epigenome_id,
    \$sth_fetched_stable_id,
    \$sth_fetched_activity,
    \$sth_fetched_epigenome_count,
    \$sth_fetched_attr_id,
    \$sth_fetched_attr_type,
    \$sth_fetched_regulatory_feature_epigenome_id,
    \$sth_fetched_analysis_id
  );

  my ($dest_slice_start, $dest_slice_end);
  my ($dest_slice_strand, $dest_slice_length, $dest_slice_sr_name);

  if ($dest_slice) {
    $dest_slice_start   = $dest_slice->start();
    $dest_slice_end     = $dest_slice->end();
    $dest_slice_strand  = $dest_slice->strand();
    $dest_slice_length  = $dest_slice->length();
    $dest_slice_sr_name = $dest_slice->seq_region_name();
  }
  
  my $project_slice_coordinates_to_destination_slice = sub {
  
    # If the destination slice starts at 1 and is forward strand, nothing needs doing
    unless ($dest_slice_start == 1 && $dest_slice_strand == 1) {

      if ($dest_slice_strand == 1) {
	$sth_fetched_seq_region_start       = $sth_fetched_seq_region_start - $dest_slice_start + 1;
	$sth_fetched_seq_region_end         = $sth_fetched_seq_region_end   - $dest_slice_start + 1;
      } else {
	my $tmp_seq_region_start = $sth_fetched_seq_region_start;
	$sth_fetched_seq_region_start        = $dest_slice_end - $sth_fetched_seq_region_end       + 1;
	$sth_fetched_seq_region_end          = $dest_slice_end - $tmp_seq_region_start + 1;
	$sth_fetched_seq_region_strand      *= -1;
      }
    }
  };

  # The current regulatory feature that is being constructed
  my $regulatory_feature_under_construction;
  
  # The linked feature sets and their activities for the regulatory feature 
  # that is being constructed
  #
  my $unique_set_of_regulatory_activities;
  
  # Closure that adds the components of a regulatory feature. This is called
  # twice, so moved into a closure to avoid code duplication in the loop 
  # below.
  #
  my $add_components_to_regulatory_feature_under_construction = sub {

    my @flattened_regulatory_activities;
    foreach my $current_epigenome_id (keys %$unique_set_of_regulatory_activities) {
      push @flattened_regulatory_activities, $unique_set_of_regulatory_activities->{$current_epigenome_id};
    }
    
    foreach my $current_regulatory_activity (@flattened_regulatory_activities) {
      $current_regulatory_activity->regulatory_feature($regulatory_feature_under_construction);
    }
    
    $regulatory_feature_under_construction->regulatory_activity(\@flattened_regulatory_activities);
    
    # Fake MultiCell regulatory behaviour.
    #
    my $multicell_regulatory_activity = $self->_fake_multicell_activity(
      $regulatory_feature_under_construction->regulatory_activity
    );

    $regulatory_feature_under_construction->add_regulatory_activity(
      $multicell_regulatory_activity
    );

  };
   
  # Closure that resets the variables holding the components. This is called
  # after a regulatory feature is done.
  #
  my $reset_components = sub {
    $unique_set_of_regulatory_activities = {};
  };

  # Because of the way the join works the rows from the linking table will 
  # appear multiple times. This helps creating unique links to feature sets.
  #
  my %seen_linked_regulatory_activity;
  
  my $fetch_slice_with_cache = sub {
    my $seq_region_id = shift;
    
    my $slice = $slice_hash{'ID:'.$seq_region_id};

    if (!$slice) {
      $slice                            = $sa->fetch_by_seq_region_id($seq_region_id);
      $slice_hash{'ID:'.$seq_region_id} = $slice;
      $sr_name_hash{$seq_region_id}     = $slice->seq_region_name();
      $sr_cs_hash{$seq_region_id}       = $slice->coord_system();
    }
    my $seq_region_name = $sr_name_hash{$seq_region_id};
    my $sr_cs   = $sr_cs_hash{$seq_region_id};
    return ($slice, $seq_region_name, $sr_cs);
  };

  # Flag to indicate that this feature should be skipped. This can happen 
  # when a feature is not on the destination slice.
  #
  my $current_feature_not_on_destination_slice = undef;
  
  ROW: while ( $sth->fetch() ) {

    # The statement is a join across multiple tables. Because of the one 
    # to many relationships between the tables the data for one regulatory
    # feature can span multiple rows. If the dbId that is fetched is different
    # from the one that is currently being built, this means that this row
    # belongs to a new regulatory feature.
    #
    my $current_row_belongs_to_new_regulatory_feature = 
      ! $regulatory_feature_under_construction 
      || ($regulatory_feature_under_construction->dbID != $sth_fetched_dbID);

    if ($current_row_belongs_to_new_regulatory_feature) {

	if ($current_feature_not_on_destination_slice) {
	
	  # So we don't duplicate the push for the feature previous to the 
	  # skip feature
	  #
	  undef $regulatory_feature_under_construction;
	  undef $current_feature_not_on_destination_slice;
	}

	# If a regulatory feature was created in the previous iteration, it 
	# is done now and construction can be finalised.
	#
	if (defined $regulatory_feature_under_construction) {
	
	  $add_components_to_regulatory_feature_under_construction->();

	  push @feature_from_sth, $regulatory_feature_under_construction;
	  
	  $reset_components->();

	  %seen_linked_regulatory_activity = ();
	}

	$seq_region_id = $self->get_core_seq_region_id($sth_fetched_efg_seq_region_id);

	if (! $seq_region_id) {
	  warn "Cannot get slice for eFG seq_region_id $sth_fetched_efg_seq_region_id\n".
	    "The region you are using is not present in the current dna DB";
	  next;
	}
    
	my $analysis = $analysis_adaptor->fetch_by_dbID($sth_fetched_analysis_id);

# 	$fset_hash{$sth_fetched_epigenome_id}   = $fset_adaptor->fetch_by_dbID($sth_fetched_epigenome_id)  if ! exists $fset_hash{$sth_fetched_epigenome_id};
	$ftype_hash{$sth_fetched_feature_type_id} = $ft_adaptor  ->fetch_by_dbID($sth_fetched_feature_type_id) if ! exists $ftype_hash{$sth_fetched_feature_type_id};
	
	# Get the slice object
	my ($slice, $seq_region_name) = $fetch_slice_with_cache->($seq_region_id);
	
	# If a destination slice was provided convert the coords
	if ($dest_slice) {
	
	  $project_slice_coordinates_to_destination_slice->();

	  my $current_feature_not_on_destination_slice = 
	    $sth_fetched_seq_region_end < 1 
	    || $sth_fetched_seq_region_start > $dest_slice_length
	    || ( $dest_slice_sr_name ne $seq_region_name );

	  next ROW
	    if ($current_feature_not_on_destination_slice);

	  $slice = $dest_slice;
	}

	$regulatory_feature_under_construction = Bio::EnsEMBL::Funcgen::RegulatoryFeature->new_fast({
	    'start'          => $sth_fetched_seq_region_start,
	    'end'            => $sth_fetched_seq_region_end,
	    '_bound_lengths' => [$sth_fetched_bound_start_length, $sth_fetched_bound_end_length],
	    'strand'         => $sth_fetched_seq_region_strand,
	    'slice'          => $slice,
	    'analysis'       => $analysis,
	    'adaptor'        => $self,
	    'dbID'           => $sth_fetched_dbID,
	    'feature_type'   => $ftype_hash{$sth_fetched_feature_type_id},
	    'stable_id'      => $sth_fetched_stable_id,
	    'epigenome_count'=> $sth_fetched_epigenome_count,
	    });
    }
    
    # Make sure there is a Bio::EnsEMBL::Funcgen::RegulatoryActivity component
    # to hold the activity and attributes.
    #
    if (! exists $unique_set_of_regulatory_activities->{$sth_fetched_epigenome_id}) {
    
      use Bio::EnsEMBL::Funcgen::RegulatoryActivity;
      my $regulatory_activity = Bio::EnsEMBL::Funcgen::RegulatoryActivity->new();
      $regulatory_activity->db($self->db);
      
      $unique_set_of_regulatory_activities->{$sth_fetched_epigenome_id} = $regulatory_activity;
    }

    # Handle regulatory evidence from the regulatory_evidence table
    #
    if (defined $sth_fetched_attr_id  && ! $current_feature_not_on_destination_slice) {

      my $regulatory_activity = $unique_set_of_regulatory_activities->{$sth_fetched_epigenome_id};
      my $regulatory_evidence = $regulatory_activity->regulatory_evidence;
      
      if ($sth_fetched_attr_type eq 'annotated') {
	$regulatory_evidence->add_supporting_annotated_feature_id($sth_fetched_attr_id);
      }
      if ($sth_fetched_attr_type eq 'motif') {
	$regulatory_evidence->add_supporting_motif_feature_id($sth_fetched_attr_id);
      }
    }

    # Handle regulatory activity from the regulatory_feature_feature_set table
    #
    if (
      ! exists $seen_linked_regulatory_activity{$sth_fetched_regulatory_feature_epigenome_id}
      && ! $current_feature_not_on_destination_slice
    ) {
      $seen_linked_regulatory_activity{$sth_fetched_regulatory_feature_epigenome_id} = 1;

      my $regulatory_activity = $unique_set_of_regulatory_activities->{$sth_fetched_epigenome_id};

      $regulatory_activity->epigenome_id($sth_fetched_epigenome_id);
      $regulatory_activity->activity($sth_fetched_activity);
    }
  }

  #handle last record
  if (defined $regulatory_feature_under_construction) {
  
    $add_components_to_regulatory_feature_under_construction->();
    push @feature_from_sth, $regulatory_feature_under_construction;
  }
  return \@feature_from_sth;
}

=head2 store

  Args       : Array of Bio::EnsEMBL::Funcgen::RegulatoryFeature objects
  Example    : $regulatory_feature_adaptor->store(@regulatory_features);
  Description: Stores given RegulatoryFeature objects in the database. Sets 
		dbID and adaptor on the objects that it stores.
  Returntype : Listref of stored RegulatoryFeatures
  Exceptions : Throws, if a list of RegulatoryFeature objects is not provided or if
               the Analysis, Epigenome and FeatureType objects are not attached or stored.
               Throws, if analysis of set and feature do not match
               Warns if RegulatoryFeature already stored in DB and skips store.
  Caller     : Regulatory Build
  Status     : Stable

=cut

sub store {
  my ($self, @regulatory_feature) = @_;

  if (scalar(@regulatory_feature) == 0) {
    throw('Must call store with a list of RegulatoryFeature objects');
  }
  foreach my $rf (@regulatory_feature) {
    if( ! ref $rf || ! $rf->isa('Bio::EnsEMBL::Funcgen::RegulatoryFeature') ) {
      throw('Feature must be an RegulatoryFeature object');
    }
  }
  
  my $sth_store_regulatory_feature = $self->prepare("
    INSERT INTO regulatory_feature (
      seq_region_id,
      seq_region_start,
      seq_region_end,
      bound_start_length,
      bound_end_length,
      seq_region_strand,
      feature_type_id,
      stable_id,
      epigenome_count,
      regulatory_build_id
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  );
  # When loading the regulatory build, this would lead to many error messages 
  # about duplicate entries being printed to screen. Errors are either handled
  # or rethrown.
  #
  $sth_store_regulatory_feature->{PrintError} = 0;

  my $sth_store_regulatory_evidence = $self->prepare("
    INSERT INTO regulatory_evidence (
      regulatory_feature_id, 
      attribute_feature_id, 
      attribute_feature_table
    ) VALUES (?, ?, ?)"
  );
  
  my $sth_regulatory_activity = $self->prepare("
    INSERT INTO regulatory_activity (
      regulatory_feature_id,
      epigenome_id,
      activity
    ) VALUES (?,?,?);
  ");

  my $db = $self->db();

  foreach my $current_regulatory_feature (@regulatory_feature) {

    my $seq_region_id;
    ($current_regulatory_feature, $seq_region_id) = $self->_pre_store($current_regulatory_feature);
    $current_regulatory_feature->adaptor($self);

    $sth_store_regulatory_feature->bind_param( 1, $seq_region_id,                                   SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 2, $current_regulatory_feature->start,               SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 3, $current_regulatory_feature->end,                 SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 4, $current_regulatory_feature->bound_start_length,  SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 5, $current_regulatory_feature->bound_end_length,    SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 6, $current_regulatory_feature->strand,              SQL_TINYINT);
    $sth_store_regulatory_feature->bind_param( 7, $current_regulatory_feature->feature_type->dbID,  SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param( 8, $current_regulatory_feature->stable_id,           SQL_VARCHAR);
    $sth_store_regulatory_feature->bind_param( 9, $current_regulatory_feature->epigenome_count,     SQL_INTEGER);
    $sth_store_regulatory_feature->bind_param(10, $current_regulatory_feature->regulatory_build_id, SQL_INTEGER);
    
    eval {
      # Store and set dbID
      $sth_store_regulatory_feature->execute;
      $current_regulatory_feature->dbID( $self->last_insert_id );
    };
    if ($@) {
      my $error_message = $@;
      
      # If the regulatory feature already exists, the error message will look 
      # like this:
      #
      # DBD::mysql::st execute failed: Duplicate entry 
      # '179363-1579-0-2-200-ENSR00000000001-0-0' for key 
      # 'uniqueness_constraint_idx' at [..]/ensembl-funcgen/modules/Bio/EnsEMBL/Funcgen/DBSQL/RegulatoryFeatureAdaptor.pm line 539, <$fh> line 10001.
      #
      # It would be possible to check, whether the regulatory feature already 
      # exists in the database, but doing so would make storing slower. (I guess)
      #
      my $regulatory_feature_already_exists = $error_message =~ /uniqueness_constraint_idx/;
      
      # The uniqueness constraint is in place to avoid duplicate entries in 
      # the regulatory feature table. 
      #
      # The regulatory build script however creates a new regulatory feature
      # for every possible activity of a regulatory feature and stores that as
      # a new feature.
      #
      # The insertion of a duplicate regulatory feature is caught here. Then 
      # the existing regulatory feature is retrieved and the new activity is 
      # added to it.
      #
      if (! $regulatory_feature_already_exists) {
      
	# If the error message is about something else, then rethrow.
	#
	throw($error_message);
      }
      my $existing_regulatory_feature = $self->fetch_by_stable_id( $current_regulatory_feature->stable_id );
      
      # This can happen during the regulatory build, when there are features,
      # but not stable ids yet. And the script is being rerun.
      #
      if (! defined $existing_regulatory_feature) {
        throw($error_message);
      }
      
      # Set the database id so the attributes and activities can be linked to this.
      $current_regulatory_feature->dbID( $existing_regulatory_feature->dbID );
    }
    
    if (! defined $current_regulatory_feature->regulatory_activity) {
      throw('Feature has no regulatory activity.');
    }
    if (ref $current_regulatory_feature->regulatory_activity ne 'ARRAY') {
      throw('Regulatory activity must be an array.');
    }
    
    use Data::Dumper;
    if (! defined $current_regulatory_feature->dbID) {
      throw(
	"Error storing the regulatory feature: "
	. Dumper($current_regulatory_feature)
      );
    }
    
    # Store the activities of the current regulatory feature in the various feature sets.
    #
    REGULATORY_ACTIVITY:
    foreach my $current_regulatory_activity (@{$current_regulatory_feature->regulatory_activity}) {

      next REGULATORY_ACTIVITY if ($current_regulatory_activity->_is_multicell);

      $sth_regulatory_activity->bind_param(1,  $current_regulatory_feature->dbID,          SQL_INTEGER);
      $sth_regulatory_activity->bind_param(2,  $current_regulatory_activity->epigenome_id, SQL_INTEGER);
      $sth_regulatory_activity->bind_param(3,  $current_regulatory_activity->activity);

      eval {
	$sth_regulatory_activity->execute();
      };
      if ($@) {
	use Carp;
	confess(
	  Dumper({
	    error => $@,
	    regulatory_activity => $current_regulatory_activity,
	    regulatory_feature => $current_regulatory_feature,
	  })
	);
      }
      
      # Store the regulatory_evidence
      #
      # Note that the regulatory build script bypasses the api for loading 
      # regulatory attributes, so this probably never gets called.
      #
      # That is a good thing, because this code links the attributes to the 
      # regulatory features. In the new schema (v85 and above) regulatory
      # attributes are linked to regulatory_feature_feature_sets.
      #
      my $regulatory_evidence = $current_regulatory_activity->regulatory_evidence;

      foreach my $id (@{$regulatory_evidence->supporting_motif_feature_ids}) {

        $sth_store_regulatory_evidence->bind_param(1, $current_regulatory_feature->dbID, SQL_INTEGER);
        $sth_store_regulatory_evidence->bind_param(2, $id,  SQL_INTEGER);
        $sth_store_regulatory_evidence->bind_param(3, 'motif', SQL_VARCHAR);
        
        $sth_store_regulatory_evidence->execute();
        
      }
      foreach my $id (@{$regulatory_evidence->supporting_annotated_feature_ids}) {

        $sth_store_regulatory_evidence->bind_param(1, $current_regulatory_feature->dbID, SQL_INTEGER);
        $sth_store_regulatory_evidence->bind_param(2, $id,  SQL_INTEGER);
        $sth_store_regulatory_evidence->bind_param(3, 'annotated', SQL_VARCHAR);
        
        $sth_store_regulatory_evidence->execute();
        
      }
    }


  }
  return @regulatory_feature;
}

=head2 fetch_all_by_Slice

  Arg [1]    : Bio::EnsEMBL::Slice
  Arg [2]    : Bio::EnsEMBL::Funcgen::FeatureSet
  Example    : my $slice = $sa->fetch_by_region('chromosome', '1');
               my $features = $regf_adaptor->fetch_all_by_Slice($slice);
  Description: Retrieves a list of features on a given slice, specific for the current
               default RegulatoryFeature set.
  Returntype : Listref of Bio::EnsEMBL::RegulatoryFeature objects
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub fetch_all_by_Slice {
  my $self  = shift;
  my $slice        = shift;
  my $feature_set  = shift;
  
  if (defined $feature_set) {
    return $self->fetch_all_by_Slice_Epigenomes($slice, [$feature_set]);
  }
  
  return $self->fetch_all_by_Slice_Epigenomes($slice);
}

sub fetch_all_by_Slice_FeatureSets {
  die("Regulatory features are no longer linked ot feature sets. Use fetch_all_by_Slice_Epigenomes instead.");
}

=head2 fetch_all_by_Slice_Epigenomes

  Arg [1]    : Bio::EnsEMBL::Slice
  Arg [2]    : Arrayref of Bio::EnsEMBL::FeatureSet objects
  Arg [3]    : optional HASHREF - params:
                   {
                    unique            => 0|1, #Get RegulatoryFeatures unique to these Epigenomes
                    include_projected => 0|1, #Consider projected features
                   }
  Example    : my $slice = $sa->fetch_by_region('chromosome', '1');
               my $features = $ofa->fetch_all_by_Slice_Epigenomes($slice, \@fsets);
  Description: Simple wrapper to set unique flag.
               Retrieves a list of features on a given slice, specific for a given list of Epigenomes.
  Returntype : Listref of Bio::EnsEMBL::RegulatoryFeature objects
  Exceptions : Throws if params hash is not valid or keys are not recognised
  Caller     : General
  Status     : At Risk

=cut

#
# This is used in
#
# ensembl-rest/lib/EnsEMBL/REST/Model/Overlap.pm
#
# There are two calls and neither uses the $params_hash parameter.
#
sub fetch_all_by_Slice_Epigenomes {
  my ($self, $slice, $requested_epigenomes) = @_;
  return $self->fetch_all_by_Slice_Epigenomes_Activity($slice, $requested_epigenomes, undef);
}

sub fetch_all_by_Slice_Activity {
  my ($self, $slice, $activity) = @_;
  return $self->fetch_all_by_Slice_Epigenomes_Activity($slice, undef, $activity);
}

sub valid_activities {
  return ('INACTIVE', 'REPRESSED', 'POISED', 'ACTIVE', 'NA');
}

sub valid_activities_as_string {
  return join ', ', valid_activities;
}

sub is_valid_activity {
  my $self = shift;
  my $activity_to_test = shift;
  
  my @valid_activity = valid_activities;  
  foreach my $current_valid_activity (@valid_activity) {
    return 1 if ($activity_to_test eq $current_valid_activity);
  }
  return;
}

sub _make_arrayref_if_not_arrayref {
  my $obj = shift;
  my $obj_as_arrayref;
  
  if (ref $obj eq 'ARRAY') {
    $obj_as_arrayref = $obj;
  } else {
    $obj_as_arrayref = [ $obj ];
  }
  return $obj_as_arrayref;
}


sub fetch_all_by_Slice_Epigenomes_Activity {
  my ($self, $slice, $requested_epigenomes, $requested_activity) = @_;
  
  if (defined $requested_activity) {
    if (! $self->is_valid_activity($requested_activity)) {
      die(
	qq(\"$requested_activity\"is not a valid activity. Valid activities are: ) . valid_activities_as_string
      );
    }
  }
  
  #explicit super call, just in case we ever re-implement in here
  my $all_regulatory_features = $self->SUPER::fetch_all_by_Slice($slice);
  
  if (defined $requested_epigenomes) {
  
    $requested_epigenomes = _make_arrayref_if_not_arrayref($requested_epigenomes);

    my $filtered_regulatory_features;
    
    REGULATORY_FEATURE: foreach my $current_regulatory_feature (@$all_regulatory_features) {
      foreach my $current_epigenome (@$requested_epigenomes) {
	if ($current_regulatory_feature->has_activity_in($current_epigenome)) {
	  push @$filtered_regulatory_features, $current_regulatory_feature;
	  next REGULATORY_FEATURE;
	}
      }
    }
    $all_regulatory_features = $filtered_regulatory_features;
  }
  
  if (defined $requested_activity) {
  
    my $filtered_regulatory_features;
    
    REGULATORY_FEATURE: foreach my $current_regulatory_feature (@$all_regulatory_features) {
      if ($current_regulatory_feature->has_epigenomes_with_activity($requested_activity)) {
	push @$filtered_regulatory_features, $current_regulatory_feature;
	next REGULATORY_FEATURE;
      }
    }
    $all_regulatory_features = $filtered_regulatory_features;
  }
  return $all_regulatory_features;
}

sub _default_where_clause {
#   return 'rfs.feature_set_id = fs.feature_set_id and rfs.regulatory_feature_id = rf.regulatory_feature_id';
  return 'rfs.regulatory_feature_id = rf.regulatory_feature_id';
}

=head2 fetch_all_by_stable_ID

  Arg [1]    : string - stable ID e.g. ENSR00000000002
  Example    : my @epigenome_regfs = @{$regf_adaptor->fetch_all_by_stable_ID('ENSR00000000001');
  Description: Retrieves a list of RegulatoryFeatures with associated stable ID. One for each Epigenome or
               'core' RegulatoryFeature set which contains the specified stable ID.
  Returntype : Listref of Bio::EnsEMBL::RegulatoryFeature objects
  Exceptions : None
  Caller     : General
  Status     : Deprecated

=cut
sub fetch_all_by_stable_ID {
  my $self = shift;
  
  use Bio::EnsEMBL::Utils::Exception qw( throw deprecate );
  deprecate("fetch_all_by_stable_ID has been deprecated and will be removed in Ensembl release 89. Use fetch_by_stable_id instead!");
  
  return [ $self->fetch_by_stable_id(@_) ];
}

=head2 fetch_all_by_attribute_feature

  Arg [1]    : Bio::Ensembl::Funcgen::AnnotatedFeature or MotifFeature
  Example    : my @regfs = @{$regf_adaptor->fetch_all_by_attribute_feature($motif_feature)};
  Description: Retrieves a list of RegulatoryFeatures which contain the given attribute feature.
  Returntype : Listref of Bio::EnsEMBL::RegulatoryFeature objects
  Exceptions : Throws is argument not valid
  Caller     : General
  Status     : At Risk

=cut

sub fetch_all_by_attribute_feature {
  my ($self, $attr_feat) = @_;

  my $attr_class = ref($attr_feat);
  
#   use Carp;
#   confess("This is never used.");
# 
  if(! exists $valid_attribute_features{$attr_class}) {
    throw("Attribute feature must be one of:\n\t".join("\n\t", keys(%valid_attribute_features)));
  }

  $self->db->is_stored_and_valid($attr_class, $attr_feat);
  my $attr_feat_table = $valid_attribute_features{$attr_class};

  my $rf_ids = $self->db->dbc->db_handle->selectall_arrayref(
    "select regulatory_feature_id "
    . "from regulatory_evidence join regulatory_activity using (regulatory_activity_id) "
    . "where attribute_feature_table='${attr_feat_table}' and attribute_feature_id=".$attr_feat->dbID
  );
  
  my @rf_ids_flattened = map { @$_ } @$rf_ids;
  my @results = $self->_fetch_by_dbID_list(@rf_ids_flattened);
  return \@results;
}

sub _fetch_by_dbID_list {
  my $self = shift;
  my @db_id = @_;
  
  my @fetched_objects;  
  foreach my $current_db_id (@db_id) {  
    my $object = $self->fetch_by_dbID($current_db_id);
    push @fetched_objects, $object;
  }
  return @fetched_objects;
}

1;
