StaticData = {
  bodyNames: {
   "sedan"=>"sedan",
   "sedan_long"=>"sedan long",
   "wagon"=>"wagon",
   "hatch_3d"=>"hatch 3d",
   "hatch_5d"=>"hatch 5d",
   "suv"=>"SUV",
   "suv_2d"=>"SUV 2-dr",
   "suv_3d"=>"SUV 3-dr",
   "suv_4d"=>"SUV 4-dr",
   "suv_5d"=>"SUV 5-dr",
   "cabrio"=>"cabriolet",
   "coupe"=>"coupe",
   "coupe_2d"=>"coupe 2-dr",
   "coupe_5d"=>"coupe 5-dr",
   "crossover"=>"crossover",
   "crossover_3d"=>"crossover 3-dr",
   "crossover_5d"=>"crossover 5-dr",
   "minivan"=>"minivan",
   "minivan_3d"=>"minivan 3-dr",
   "minivan_5d"=>"minivan 5-dr",
   "van"=>"van",
   "pickup"=>"pickup",
   "pickup_2d"=>"pickup 2-dr",
   "pickup_4d"=>"pickup 4-dr",
  },
  premiumBrandKeys: %w(mercedes_benz audi bmw lexus infinity acura volvo cadillac range_rover),
  parameter_names: {
    top_speed: "Top Speed",
    acceleration_0_100_kmh: "Acelleration",
    consumption_city: "Consumption (city)",
    consumption_highway: "Consumption (highway)",
    consumption_mixed: "Consumption (mixed)",
    engine_volume: "Displacement",
    cylinder_count: "Cyliders",
    valves_per_cylinder: "Valves per Cylider",
    compression: "Compression",
    bore: "Bore",
    max_power: "Power",
    max_power_kw: "Power, kW",
    # max_power_range_start: :value,
    max_torque: "Torque",
    # max_torque_range_start: :value,
    gears: "Gears",
    length: "Length",
    width: "Width",
    height: "Height",
    ground_clearance: "Ground Clearance",
    tires: "Tires",
    front_tire_rut: "Front Tire Rut",
    rear_tire_rut: "Rear Tire Rut",
    wheelbase: "Wheelbase",
    luggage_min: "Luggage (min)",
    luggage_max: "Luggage (max)",
    tank_capacity: "Tank Capacity",
    gross_mass: "Gross Weight",
    kerbweight: "Kerb Weight",
    doors: "Doors Count",
    seats: "Seats Count",
    produced_since: "Produced Since",
    price: "Price",
  },
  parameter_units: {
    top_speed: :kmh,
    acceleration_0_100_kmh: :s,
    consumption_city: :l100km,
    consumption_highway: :l100km,
    consumption_mixed: :l100km,
    engine_volume: :cc,
    cylinder_count: :count,
    valves_per_cylinder: :count,
    compression: :value,
    bore: :mm,
    max_power: :ps,
    max_power_kw: :kw,
    max_power_range_start: :value,
    max_torque: :nm,
    max_torque_range_start: :value,
    gears: :count,
    length: :mm,
    width: :mm,
    height: :mm,
    ground_clearance: :mm,
    tires: :tires,
    front_tire_rut: :mm,
    rear_tire_rut: :mm,
    wheelbase: :mm,
    luggage_min: :l,
    luggage_max: :l,
    tank_capacity: :l,
    gross_mass: :kg,
    kerbweight: :kg,
    doors: :count,
    seats: :count,
    produced_since: :date,
    price: :rouble,
  },
  parameter_unit_names: {
    kmh: "km/h",
    s: "s",
    l100km: "l/100km",
    cc: "cc",
    count: "",
    value: "",
    mm: "mm",
    ps: "ps",
    kw: "kw",
    nm: "Nm",
    tires: "",
    l: "l",
    kg: "kg",
    date: "",
    rouble: "",  
  },
  categoryNames: {
     A: "City (A class)",
     B: "Supermini (B class)",
     C: "Compact (C/Golf class) ",
     D: "Family (D class)",
     E: "Business (E class)",
     F: "Premium Sedans",
    Xb: "Very Compact SUV",
    Xc: "Compact SUV",
    Xd: "Compact+ SUV",
    Xe: "Mid-Size SUV",
    Xf: "Full-Size SUV",
    Xx: "Offroad SUV",
    Wx: "AWD Wagon",
    Sr: "Roadster",
    Sc: "Sportcar",
    Mb: "Mini MPV",
    Mc: "Compact MPV",
    Me: "Mid-Size MPV",
    Pc: "Compact Pickup",
    Pd: "Full-Size Pickup",  
  },
  brand_names: {
		acura: "Acura",
		alfa_romeo: "Alfa Romeo",
		audi: "Audi",
		bmw: "BMW",
		cadillac: "Cadillac",
		chery: "Chery",
		chevrolet: "Chevrolet",
		chrysler: "Chrysler",
		citroen: "Citroen",
		daewoo: "Daewoo",
		dodge: "Dodge",
		fiat: "FIAT",
		ford: "Ford",
		gaz: "ГАЗ",
		great_wall: "Great Wall",
		honda: "Honda",
		hummer: "Hummer",
		hyundai: "Hyundai",
		infiniti: "Infiniti",
		jaguar: "Jaguar",
		jeep: "Jeep",
		kia: "Kia",
		land_rover: "Land Rover",
		lexus: "Lexus",
		mazda: "Mazda",
		mercedes_benz: "Mercedes-Benz",
		mini: "MINI",
		mitsubishi: "Mitsubishi",
		nissan: "Nissan",
		opel: "Opel",
		peugeot: "Peugeot",
		porsche: "Porsche",
		renault: "Renault",
		saab: "Saab",
		seat: "SEAT",
		skoda: "Skoda",
		ssangyong: "SsangYong",
		subaru: "Subaru",
		suzuki: "Suzuki",
		toyota: "Toyota",
		uaz: "УАЗ",
		vaz: "ВАЗ (LADA)",
		volkswagen: "Volkswagen",
		volvo: "Volvo",
	},  
}
