=pod 

=head1 NAME

    Bio::EnsEMBL::Funcgen::Hive::Config::PeaksLinkQC

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 LICENSE

    Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
    Copyright [2016] EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License
    is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

=head1 CONTACT

=cut
package Bio::EnsEMBL::Funcgen::Hive::Config::PeaksLinkQC;

use strict;
use warnings;

use Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf;
use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub pipeline_analyses {
    my ($self) = @_;
    return [
      {
	-logic_name    => 'CallDefaultPeaks',
	-flow_into => {
	  MAIN => {
	    PeaksQc => INPUT_PLUS({
		'source' => 'CallDefaultPeaks',
		'peak_caller' => 'SWEmbl',
	      } 
	    ) 
	  },
	},
      },
      {
	-logic_name    => 'CallBroadPeaks',
	-flow_into => {
	  MAIN => {
	    PeaksQc => INPUT_PLUS({
		'source' => 'CallBroadPeaks',
		'peak_caller' => 'CCAT',
	      } 
	    ) 
	  },
	},
      },
      {
	-logic_name    => 'CallTightPeaks',
	-flow_into => {
	  MAIN => {
	    PeaksQc => INPUT_PLUS({
		'source' => 'CallTightPeaks',
		'peak_caller' => 'SWEmbl',
	      } 
	    ) 
	  },
	},
      },
      {
	-logic_name    => 'CallIDRPeaks',
	-flow_into => {
	  MAIN => {
	    PeaksQc => INPUT_PLUS({
		'source' => 'CallIDRPeaks',
		'peak_caller' => 'SWEmbl',
	      } 
	    ) 
	  },
	},
      },
      {   -logic_name => 'PeaksQc',
	  -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      },
   ];
}

1;
