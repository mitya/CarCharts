class ModsController < UIViewController
  attr_accessor :model, :mods, :modsByBody, :filteredMods, :tableView, :toolbar

  def initialize(model = nil)
    self.model = model
    self.hidesBottomBarWhenPushed = YES
  end

  def viewDidLoad
    self.title = model.name
    self.mods = model.mods
    self.tableView = setupTableViewWithStyle(UITableViewStylePlain)
    
    self.applyFilter
    self.toolbarItems = toolbarItemsForFilter.presence    
    self.navigationItem.backBarButtonItem = ES.textBBI("Versions")
  end
  
  def shouldAutorotateToInterfaceOrientation(interfaceOrientation)
    true
  end
  
  ####
  
  def numberOfSectionsInTableView(tv)
    @modsByBody.count > 0 ? @modsByBody.count : 1
  end

  def tableView(tv, numberOfRowsInSection:section)
    return 0 if section >= @modsByBody.count
    @modsByBody[ modsByBody.keys[section] ].count
  end

  def tableView(tv, titleForHeaderInSection:section)
    Metadata.bodyNames[ modsByBody.keys[section] ]
  end

  def tableView(tv, titleForFooterInSection:section)
    if section == tableView.numberOfSections - 1
      hiddenModsCount = mods.count - filteredMods.count
      if @modsByBody.count == 0
        "All #{hiddenModsCount} #{"model".pluralizeFor(hiddenModsCount)} are filtered out"
      else
        hiddenModsCount > 0 ? "There are also #{hiddenModsCount} #{"model".pluralizeFor(hiddenModsCount)} hidden" : nil
      end
    end
  end

  def tableView(tv, cellForRowAtIndexPath:indexPath)
    mod = modsByBody.objectForIndexPath(indexPath)

    cell = tv.dequeueReusableCell(klass: DSCheckmarkCell) do |cell|
      cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton
    end
    
    cell.imageView.image = mod.selected? ? UIImage.imageNamed("list_checkmark") : UIImage.imageNamed("list_checkmark_stub")
    cell.textLabel.textColor = mod.selected? ? ES.checkedTableViewItemColor : UIColor.darkTextColor
    cell.textLabel.text = mod.nameWithVersion
    cell
  end

  def tableView(tv, didSelectRowAtIndexPath:indexPath)
    tv.deselectRowAtIndexPath(indexPath, animated:YES)

    mod = modsByBody.objectForIndexPath(indexPath)
    mod.select!

    cell = tv.cellForRowAtIndexPath(indexPath)
    cell.toggleLeftCheckmarkAccessory
  end
  
  def tableView(tableView, accessoryButtonTappedForRowWithIndexPath:indexPath)
    mod = modsByBody.objectForIndexPath(indexPath)
    navigationController.pushViewController ModController.new(mod), animated:YES
  end
  
  ####
  
  def applyFilter(options = {})
    Disk.filterOptions = Disk.filterOptions.merge(options).delete_if { |k,v| !v }
    opts = Disk.filterOptions
    self.filteredMods = Disk.filterOptions.empty? ? mods : mods.select do |mod|
      next false if Disk.filterOptions[:at] && mod.automatic?
      next false if Disk.filterOptions[:mt] && mod.manual?
      next false if Disk.filterOptions[:sedan] && mod.sedan?
      next false if Disk.filterOptions[:hatch] && mod.hatch?
      next false if Disk.filterOptions[:wagon] && mod.wagon?
      next false if Disk.filterOptions[:gas] && mod.gas?
      next false if Disk.filterOptions[:diesel] && mod.diesel?      
      next true
    end
    self.modsByBody = filteredMods.group_by { |m| m.body }
    tableView.reloadData
  end
  
  def addToModSet(button)
    indexPath = tableView.indexPathForCell(button.superview)
    mod = modsByBody.objectForIndexPath(indexPath)
    # nothing for now
  end
  
  def toolbarItemsForFilter
    availableFilterOptions = Mod.filterOptionsForMods(mods)

    if availableFilterOptions[:transmission].count > 1
      @transmissionFilter = DSMultisegmentView.new
      @transmissionFilter.addButton("MT", Disk.filterOptions[:mt]) { |state| applyFilter(mt: state) } if availableFilterOptions[:mt]
      @transmissionFilter.addButton("AT", Disk.filterOptions[:at]) { |state| applyFilter(at: state) } if availableFilterOptions[:at]
    end

    if availableFilterOptions[:body].count > 1
      @bodyFilter = DSMultisegmentView.new
      @bodyFilter.addButton("Sed", Disk.filterOptions[:sedan]) { |state| applyFilter(sedan: state) } if availableFilterOptions[:sedan]
      @bodyFilter.addButton("Wag", Disk.filterOptions[:wagon]) { |state| applyFilter(wagon: state) } if availableFilterOptions[:wagon]
      @bodyFilter.addButton("Hat", Disk.filterOptions[:hatch]) { |state| applyFilter(hatch: state) } if availableFilterOptions[:hatch]
    end

    if availableFilterOptions[:fuel].count > 1
      @fuelFilter = DSMultisegmentView.new
      @fuelFilter.addButton("Gas", Disk.filterOptions[:gas]) { |state| applyFilter(gas: state) } if availableFilterOptions[:gas]
      @fuelFilter.addButton("Di", Disk.filterOptions[:diesel]) { |state| applyFilter(diesel: state) } if availableFilterOptions[:diesel]
    end

    [@transmissionFilter, @bodyFilter, @fuelFilter].compact.map { |filter| ES.customBBI(filter) }.
      arraySeparatedBy(ES.systemBBI(UIBarButtonSystemItemFlexibleSpace, target:nil, action:nil))
  end  
end