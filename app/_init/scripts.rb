module Scripts
  module_function
  
  def modNames
    ModelGeneration.all.map { |m| m.mods.first.modName(Mod::NameBodyEngineVersion | Mod::NameModel) }.sort_by(&:length).reverse
  end

  def run
  end
end
