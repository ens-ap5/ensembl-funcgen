#
# Ensembl module for Bio::EnsEMBL::Funcgen::PredictedFeature
#
# You may distribute this module under the same terms as Perl itself

=head1 NAME

Bio::EnsEMBL::PredictedFeature - A module to represent a feature mapping as 
predicted by the eFG pipeline.

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::PredictedFeature;

my $feature = Bio::EnsEMBL::Funcgen::PredictedFeature->new(
	-SLICE         => $chr_1_slice,
	-START         => 1_000_000,
	-END           => 1_000_024,
	-STRAND        => -1,
    -DISPLAY_LABEL => $text,
    -ANALYSIS_ID   => $anal_id,
    -SCORE         => $score,
); 



=head1 DESCRIPTION

A PredictedFeature object represents the genomic placement of a prediction
generated by the eFG analysis pipeline, which may have originated from one or many
separate experiments.

=head1 AUTHOR

This module was created by Nathan Johnson.

This module is part of the Ensembl project: http://www.ensembl.org/

=head1 CONTACT

Post comments or questions to the Ensembl development list: ensembl-dev@ebi.ac.uk

=head1 METHODS

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Funcgen::PredictedFeature;

use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::Utils::Exception qw( throw );
use Bio::EnsEMBL::Feature;
use Bio::EnsEMBL::Funcgen::FeatureType;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::Feature);


=head2 new

  Arg [-PROBE]        : Bio::EnsEMBL::Funcgen::OligoProbe - probe
        An OligoFeature must have a probe. This probe must already be stored if
		you plan to store the feature.
  Arg [-SCORE]: (optional) int
        Score assigned by analysis pipeline
  Arg [-ANALSIS_ID]         : int
        Analysis database ID.
  Arg [-SLICE]        : Bio::EnsEMBL::Slice
        The slice on which this feature is.
  Arg [-START]        : int
        The start coordinate of this feature relative to the start of the slice
		it is sitting on. Coordinates start at 1 and are inclusive.
  Arg [-END]          : int
        The end coordinate of this feature relative to the start of the slice
		it is sitting on. Coordinates start at 1 and are inclusive.
  Arg [-DISPLAY_LABEL]: string
        Display label for this feature
  Arg [-STRAND]       : int
        The orientation of this feature. Valid values are 1, -1 and 0.
  Arg [-dbID]         : (optional) int
        Internal database ID.
  Arg [-ADAPTOR]      : (optional) Bio::EnsEMBL::DBSQL::BaseAdaptor
        Database adaptor.
  Example    : my $feature = Bio::EnsEMBL::Funcgen::PredictedFeature->new(
	-PROBE         => $probe,
	-SLICE         => $chr_1_slice,
	-START         => 1_000_000,
	-END           => 1_000_024,
	-STRAND        => -1,
    -DISPLAY_LABEL => $text,
    -ANALYSIS_ID   => $anal_id,
    -SCORE         => $score,
    ); 



  Description: Constructor for PredictedFeature objects.
  Returntype : Bio::EnsEMBL::Funcgen::PredictedFeature
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub new {
	my $caller = shift;
	
	my $class = ref($caller) || $caller;
	
	my $self = $class->SUPER::new(@_);
	
	my ($anal_id, $display_label, $coord_sys_id, $score, $ft_id)
		= rearrange(['ANALYSIS_ID', 'DISPLAY_LABEL', 'COORD_SYSTEM_ID', 'SCORE', 'FEATURE_TYPE_ID'], @_);
	
	$self->score($score);
	$self->display_label($display_label);
	$self->analysis_id($anal_id);
	$self->feature_type_id($ft_id);

	#do we need to validate this against the db?  Grab from slice and create new if not present? 
	#Will this be from the dnadb? Or will this work differently for PredictedFeatures?
	
	$self->coord_system_id($coord_sys_id);
	
	return $self;
}

=head2 new_fast

  Args       : Hashref with all internal attributes set
  Example    : none
  Description: Quick and dirty version of new. Only works if the code is very
               disciplined.
  Returntype : Bio::EnsEMBL::Funcgen::PredictedFeature
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub new_fast {
   my ($class, $hashref)  = @_;


   return bless ($hashref, $class);
}

=head2 score

  Arg [1]    : (optional) int - score
  Example    : my $score = $feature->score();
  Description: Getter and setter for the score attribute for this feature. 
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Low Risk

=cut

sub score {
    my $self = shift;
	
    $self->{'score'} = shift if @_;
		
    return $self->{'score'};
}

=head2 display_label

  Arg [1]    : string - display label
  Example    : my $label = $feature->display_label();
  Description: Getter and setter for the display label of this feature.
  Returntype : str
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub display_label {
    my $self = shift;
	
    $self->{'display_label'} = shift if @_;
	
    return $self->{'display_label'};
}


=head2 coord_system_id

  Arg [1]    : int - dbID of corresponding coord_system for DB of origin
  Example    : $feature->coord_system_id($cs_id);
  Description: Getter and setter for the coord system id for this feature.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Low Risk

=cut

sub coord_system_id {
    my $self = shift;
	
    $self->{'coord_system_id'} = shift if @_;
	
    return $self->{'coord_system_id'};
}



=head2 analysis_id

  Args       : int - analysis id 
  Example    : my $anal_id = $feature->analysis_id();
  Description: Getter/Setter for the analysis_id attribute for this feature.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Low Risk
             
=cut

sub analysis_id {
    my $self = shift;

	$self->{'analysis_id'} = shift if @_;
	
    return $self->{'analysis_id'};
}

=head2 feature_type_id

  Args       : int - feature type id
  Example    : my $target_id = $feature->feature_type_id();
  Description: Getter/Setter for the feature_type_id attribute for this feature.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Low Risk
             
=cut

sub feature_type_id {
    my $self = shift;

	$self->{'feature_type_id'} = shift if @_;
	
    return $self->{'feature_type_id'};
}

#Hacky placeholder mehtod as I haven't written FeatureType or FeatureTypeAdaptor yet

=head2 type

  Args       : Bio::EnsEMBL::Funcgen::FeatureType
  Example    : my $type_name = $feature->type()->name();
  Description: Getter/Setter for the type attribute for this feature.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Medium Risk
             
=cut

sub type {
    my $self = shift;

    #$self->{'type'} = shift if @_;
	

    if( ! $self->{'type'}){

      my ($name, $desc, $class);

      if(self->db->species() =~ /homo/i){
	$desc = "Generalised Histone 3 Lysine acetylation";
	$name = "H3kgac";
	$class = "HISTONE";
      }else{
	$desc = "MEFf";
	$name = "MEFf";
	$class = "HISTONE";
      }


      my $ft = Bio::EnsEMBL::Funcgen::FeatureType->new
		(
		 -NAME => $name,
		 -DESCRIPTION => $desc,
		 -CLASS => $class, 
		); 

      $self->{'type'} = $ft;
    }
    

    


    return $self->{'type'};
}




#other methods
#type!! Add to BaseFeature?  Hard code val in oligo_feature
#analysis? Use AnalsisAdapter here, or leave to caller?
#sources/experiments
#target, tar



1;

