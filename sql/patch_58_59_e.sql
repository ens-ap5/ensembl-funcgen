-- Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

# patch_58_59_e.sql
#
# title: add meta schema_type
#
# description:
# Add meta entry denoting funcgen schema_type

INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_type', 'funcgen');
# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_58_59_e.sql|meta.schema_type');


