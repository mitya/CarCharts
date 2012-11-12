class YAFinalParser
  SPACE_RE = %r{\s+}

  def build_modifications
    mods = JSON.load(WORKDIR + "ya-mods-rus.json")
    parsed_mod_hashes = {}
    parsed_mod_arrays = {}
    
    mods_count = $ya_number_of_mods_to_convert || 1_000_000
    mods.first(mods_count).each do |old_key, mod|
      parsed = {}
      
      mod.each_pair do |title, string|
        next if title =~ /^\w+$/
        
        key = Translations_Parameters[title] || raise("Key not found for '#{title}'")

        case key
        when :front_suspension, :rear_suspension, :front_brakes, :rear_brakes, :model_title, :body_title, :body_type, :price, :engine_title, :engine_spec, :category
          # ignore          
        when :fuel_consumption
          values = string.split(%r{ / }).map(&:to_f)
          parsed[:consumption_city], parsed[:consumption_highway], parsed[:consumption_mixed] = values
        when :bore_and_stroke
          values = string.split('x').map(&:to_f)
          parsed[:bore], parsed[:stroke] = values
        when :max_power
          values = string.split(%r{ / }).map(&:to_i)
          parsed[:max_power], parsed[:max_power_kw], parsed[:max_power_range_start], parsed[:max_power_range_end] = values
        when :max_torque
          values = string.split(%r{ / }).map(&:to_i)
          parsed[:max_torque], parsed[:max_torque_range_start], parsed[:max_torque_range_end] = values
        when :tires
          parsed[:tires] = string.gsub(SPACE_RE, ' ')
        when :luggage_capacity
          values = string.split(SPACE_RE).map(&:to_i)
          parsed[:luggage_min], parsed[:luggage_max] = values.first, values.last
        when :seats
          string = '4' if string == '2+2'
          values = string.split(SPACE_RE).map(&:to_i)
          parsed[:seats_min], parsed[:seats_max] = values.first, values.last
        when :countries
          names = string.split(SPACE_RE)
          names.delete("Корея") && names.delete("Южная") && names.push("Южная Корея") if names.include?("Корея")
          names.map! { |rus_name| Rus_CountryName_Codes[rus_name] }          
          parsed[:countries] = names.join(' ')
        when :drive
          string = Translations_Values[key][string]
          parsed[key] = string == '4WD' ? 'AWD' : string
        when :produced_since, :produced_till
          if string.length > 4
            month, year = string.split(SPACE_RE)
            month_number = Rus_Months.index(month) + 1
            parsed[key] = "#{year}.#{month_number.to_s.rjust(2, '0')}"
          else
            parsed[key] = string
          end
        when :top_speed, :displacement, :cylinder_count, :cylinder_valves, :gears, :max_power, :max_power_kw, :max_torque,
             :max_power_revs, :max_torque_revs, :length, :width, :height, :ground_clearance, :front_tire_rut, :rear_tire_rut,
             :wheelbase, :luggage_capacity, :tank_capacity, :kerbweight, :gross_mass, :doors
          parsed[key] = string.to_i
        when :acceleration_100kmh, :bore, :stroke, :compression, :displacement_key
          parsed[key] = string.to_f
        when :cylinder_placement, :injection, :engine_layout, :front_suspension, :rear_suspension, 
             :front_brakes, :rear_brakes, :fuel, :fuel_rating, :compressor, :transmission
          translations = Translations_Values.fetch(key)
          parsed[key] = translations[string] if translations
        else
          parsed[key] = string
        end        
      end
      
      # replace dashes with spaces in the key
      new_key = upgrade_key(old_key)

      # store key parts as individual elements
      brand_key, model_version, years, body, model_subkey, version_subkey, engine, power, transmission, drive = parse_new_key(new_key)
      parsed[:body] = body
      parsed[:model_key] = [brand_key, model_subkey].join('--')
      parsed[:version_key] = version_subkey
      parsed[:displacement_key] = engine[0..-2]

      # remove nil values because plists can't contain it
      parsed.delete_if { |k,v| v.nil? }

      # create an array with the hash contents
      array = Keys_Used.each_with_index.map { |k, i| parsed[k] || '' }

      parsed_mod_arrays[new_key] = array
      parsed_mod_hashes[new_key] = parsed
    end

    KK.save_plist parsed_mod_arrays, "db-mods", OUTDIR
    KK.save_plist parsed_mod_hashes, "db-mods-kv", OUTDIR
    KK.save_data  parsed_mod_hashes, "db-mods-kv", OUTDIR
  end
  
  def build_metadata
    mods = JSON.load(OUTDIR + "db-mods-kv.json")
    bodies = JSON.load(WORKDIR + "ya-bodies-2.json")
    
    model_keys = mods.map { |key, mod| key.split(' ').first(2).join('--').sub(/\..+/, '') }.uniq

    model_names = model_keys.each_with_object({}) do |key, model_names|
      body = bodies.detect { |b| b['key'].starts_with?(key) }
      model_names[key] = body.fetch('model_title') if body
    end

    new_model_names = Reductions_Body_Model.each_with_object({}) do |(brand_old_body, new_model_str), new_model_names|
      brand, _ = brand_old_body.split('--')
      body, model_name = new_model_str.split(' ', 2)
      model = KK.escape(model_name)
      new_model_names["#{brand}--#{model}"] = model_name
    end    
    
    %w(a b c cl clc clk cls e g gl glk m r s sl slk slr).each do |key|
      model_names["mercedes_benz--#{key}"] = model_names["mercedes_benz--#{key}"] + "-Class"
    end
    
    all_model_names = model_names.merge(new_model_names)
    branded_model_names = all_model_names.each_with_object({}) do |(key, title), memo|
      brand_name = Attributes_Vendor_Name[ key.split('--').first ]
      memo[key] = "#{brand_name} #{title}"
    end

    all_model_names.merge!(Attributes_Model_Name)
    branded_model_names.merge!(Attributes_Model_BrandedName)

    model_brands = Hash[ all_model_names.keys.map { |key| brand = key.split('--').first; [key, brand] } ]

    model_info = model_keys.sort.reduce({}) do |hash, key|
      hash[key] = [all_model_names[key], branded_model_names[key], model_brands[key], ModelClassification[key]]
      hash
    end

    model_versions = {}
    Reductions_Body_Version.each do |brand__model__extbody, body__version_title|
      brand, model, _ = brand__model__extbody.split('--')
      body, version_title = body__version_title.split(' ', 2)
      version_key = KK.escape(version_title)
      model_versions["#{brand}--#{model}.#{version_key}"] = version_title
    end

    metadata = {}    
    metadata['model_keys'] = model_keys.sort
    metadata['model_info'] = model_info    
    metadata['model_versions'] = model_versions
    metadata['models_by_class'] = inverted_classification
    metadata['models_by_brand'] = all_model_names.keys.inject({}) { |hash, key| brand = key.split('--').first; (hash[brand] ||= []) << key; hash }    
    metadata['parameters'] = Keys_Used

    KK.save_plist metadata, "db-metadata", OUTDIR
  end

private

  #  in: mercedes_benz--cl--2010_2012--coupe_amg---6.0i-630ps-AT-RWD
  # out: mercedes_benz cl.amg 2010-2012 coupe 6.0i-630ps-AT-RWD
  def upgrade_key(old_key)
    brand, model, years, body, engine = old_key.split(/---?/)
    brand_body = "#{brand}--#{body}"
    brand_model_body = "#{brand}--#{model}--#{body}"

    years.gsub!('_', '-')

    body = Reductions_Body_Body.fetch(brand_body, body)

    if model_str = Reductions_Body_Model[brand_body]
      body, model_name = model_str.split(' ', 2)
      model = KK.escape(model_name)
    end

    if version_str = Reductions_Body_Version[brand_model_body]
      body, version = version_str.split(' ', 2)
      model = "#{model}.#{KK.escape(version)}"
    end
    
    new_key = [brand, model, years, body, engine].join(' ')
  end

  def parse_new_key(key)
    brand_key, model_version, years, body, agregate = key.split(' ')
    model_subkey, version_subkey = model_version.split('.')
    engine, power, transmission, drive = agregate.split('-')
    [brand_key, model_version, years, body, model_subkey, version_subkey, engine, power, transmission, drive]
  end

  def inverted_classification
    klasses = {}
    ModelClassification.each do |key, klass|
      next if klass.blank?
      klasses[klass] ||= []
      klasses[klass] << key
    end
    klasses
  end
end