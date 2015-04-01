class YA2Parser
  def step_83 # build metadata
    models = CW.read_hash('03-models', openstruct: true)
    mods = CW.read_data_in_binary('08.2-mods')
  
    family_keys = mods.map { |key, mod| mod['model_key'] }.uniq.sort
    brand_keys = mods.map { |key, mod| key.split.first }.uniq.sort
    family_keys_set = family_keys.to_set

    generation_keys = mods.values.map { |mod| mod['generation_key'] }.uniq.sort
  
    generation_rows = generation_keys.each_with_object({}) do |generation_key, result|
      mark_key, model_self_key, year = generation_key.split('--')
      model_key = [mark_key, model_self_key].join('--')
      model = models[model_key]
      generation_self_title = "#{model.title} #{year}"
      result[generation_key] = [model_key, year, generation_self_title]
    end

    family_rows = family_keys.each_with_object({}) do |key, result| # { 'bmw--x6' =>  ['X6', 'BMW X6', 'bmw', 'Xe'], ... }
      model = models[key]
      generations = generation_keys.select { |g| g.start_with?(key + '--') }
      result[key] = [ model.title, model.full_title, model.mark, CWD.model_classification[key] || '', generations ]
    end


    models_by_brand = family_keys.each_with_object({}) do |key, result|
      model = models[key]
      (result[model.mark] ||= []) << key
    end


    models_by_class = CWD.model_classification.each_with_object({}) do |(key, klass), result|
      xputs "unused classification key: #{key}" if klass && !family_keys_set.include?(key)
      next unless family_keys_set.include?(key)
      next unless klass
      (result[klass] ||= []) << key
    end


    brand_names = CWD.adjusted_brand_names
    brand_names.delete_if { |key, name| !brand_keys.include?(key) }
  
  
    sample_sets = YAML.load_file("crawler/data-sample-sets.yml")
  
      
    metadata = {}
    metadata['generation_rows'] = generation_rows
    metadata['generation_keys'] = generation_keys.sort
    metadata['family_rows'] = family_rows
    metadata['family_keys'] = family_rows.keys.sort
    metadata['category_models'] = models_by_class
    metadata['brand_models'] = models_by_brand
    metadata['brand_names'] = brand_names
    metadata['parameter_keys'] = CWD.used_fields
    metadata['sample_sets'] = sample_sets

    CW.write_data_to_plist "08.3-metadata", metadata
    CW.write_data "debug-08.3-metadata", metadata
  end
end
