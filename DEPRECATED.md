Ensembl Funcgen Deprecated Methods
==================================

This file contains the list of methods, modules and scripts deprecated in the Ensembl Funcgen API.
A method is deprecated when it is not functional any more (schema/data change) or has been replaced by a better one.
Backwards compatibility is provided whenever possible.
When a method is deprecated, a deprecation warning is thrown whenever the method is used.
The warning also contains instructions on replacing the deprecated method and when it will be removed.
A year after deprecation (4 Ensembl releases), the method is removed from the API.

### Removed in Ensembl Release 88 ###
 - Bio::Ensembl::Funcgen::**Channel**
 - Bio::Ensembl::Funcgen::DBSQL::**ChannelAdaptor**
 - Bio::Ensembl::Funcgen::**ExperimentalChip**
 - Bio::Ensembl::Funcgen::DBSQL::**ExperimentalChipAdaptor**
 - Bio::Ensembl::Funcgen::**InputSet**
 - Bio::Ensembl::Funcgen::DBSQL::**InputSetAdaptor**
 - Bio::Ensembl::Funcgen::**ResultFeature**
 - Bio::Ensembl::Funcgen::DBSQL::**ResultFeatureAdaptor**
 - Bio::Ensembl::Funcgen::Collector::**ResultFeature**

### Removed in Ensembl Release 85 ###
 - Bio::Ensembl::Funcgen::**Experiment**::*date()*
 - Bio::Ensembl::Funcgen::**ResultSet**::*get_replicate_set_by_chip_channel_id()*
 - Bio::Ensembl::Funcgen::DBSQL::**BaseAdaptor**::*list_dbIDs()*
 - Bio::Ensembl::Funcgen::DBSQL::**BaseAdaptor**::*_constrain_status()*
 - Bio::Ensembl::Funcgen::DBSQL::**BaseAdaptor**::*fetch_all_by_status()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_regulatory_feature_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_probeset_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_feature_type_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_external_feature_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_annotated_feature_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**DBEntryAdaptor**::*list_probe_ids_by_extid()*
 - Bio::Ensembl::Funcgen::DBSQL::**FeatureSetAdaptor**::*fetch_all_by_type()*
 - Bio::Ensembl::Funcgen::DBSQL::**InputSubsetAdaptor**::*fetch_by_name_and_experiment()*
 - Bio::Ensembl::Funcgen::DBSQL::**ProbeFeatureAdaptor**::*fetch_all_by_probeset()*
 - Bio::Ensembl::Funcgen::DBSQL::**ResultFeatureAdaptor**::*fetch_all()*
 - Bio::Ensembl::Funcgen::DBSQL::**ResultSetAdaptor**::*store_dbfile_data_dir()*
 - Bio::Ensembl::Funcgen::DBSQL::**ResultSetAdaptor**::*_fetch_dbfile_data_dir()*

### Removed in Ensembl Release 84 ###
 - Bio::Ensembl::Funcgen::**Dataset**::*add_supporting_sets()*
 - Bio::Ensembl::Funcgen::**Dataset**::*_validate_and_set_types()*
 - Bio::Ensembl::Funcgen::**InputSubset**::*input_set()*
 - Bio::Ensembl::Funcgen::**InputSubset**::*archive_id()*
 - Bio::Ensembl::Funcgen::**InputSubset**::*display_url()*
 - Bio::Ensembl::Funcgen::**Probe**::*add_Analysis_score()*
 - Bio::Ensembl::Funcgen::**Probe**::*add_Analysis_CoordSystem_score()*
 - Bio::Ensembl::Funcgen::**Probe**::*get_score_by_Analysis()*
 - Bio::Ensembl::Funcgen::**Probe**::*get_score_by_Analysis_CoordSystem()*
 - Bio::Ensembl::Funcgen::**Probe**::*get_all_design_scores()*
 - Bio::Ensembl::Funcgen::DBSQL::**DataSetAdaptor**::*store_updated_sets()*
 - Bio::Ensembl::Funcgen::HiveConfig::**Alignment_conf.pm**
 - Bio::Ensembl::Funcgen::HiveConfig::**Peaks_conf.pm**
 - Bio::Ensembl::Funcgen::HiveConfig::**Annotation_conf.pm**
 - Bio::Ensembl::Funcgen::HiveConfig::**Dnase_profile_conf.pm**
 - Bio::Ensembl::Funcgen::HiveConfig::**MotifFinder_conf.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**Alignment.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**AnnotateRegulatoryFeatures.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**Annotation.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**ClusterMotifs.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**ConvergeReplicates.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**Funcgen.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**Import.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**InferMotifs.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**MakeDnaseProfile.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**Motif.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**RunBWA.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**RunCCAT.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**RunCentipede.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**RunMACS.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**RunSWEmbl.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**SWEmbl.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**SetupAlignmentPipeline.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**SetupAnnotationPipeline.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**SetupMotifInference.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**SetupPeaksPipeline.pm**
 - Bio::EnsEMBL::Funcgen::RunnableDB::**WrapUpAlignment.pm**

 - scripts/pipeline/**configure_hive.pl**
 - scripts/regulatory_build/**load_segmentation.pl**
 - scripts/regulatory_build/**unpack_swilder_segmentation.pl**