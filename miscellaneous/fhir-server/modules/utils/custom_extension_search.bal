// Custom extension search functionality has been removed.
// Search parameters (including custom ones) are now indexed uniformly in the
// sp_string / sp_token / sp_date / sp_number / sp_quantity / sp_uri / sp_reference / sp_coords
// tables via search_param_extractor.bal. Custom search parameters are stored in
// search_param_definitions with is_custom = TRUE.
