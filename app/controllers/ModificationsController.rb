class ModificationsController < UITableViewController
  attr_accessor :model, :mods, :modsByBody, :filteredMods

  def viewDidLoad
    super
    
    self.title = model.name
    self.mods = model.modifications    
    
    applyFilter
    
    availableOptions = Model.availableFilterOptionsFor(mods)

    @transmissionFilter = MultisegmentView.new
    @transmissionFilter.addButton("MT", Model.filterOptions[:mt]) { |state| applyFilter(mt: state) } if availableOptions[:mt]
    @transmissionFilter.addButton("AT", Model.filterOptions[:at]) { |state| applyFilter(at: state) } if availableOptions[:at]

    @bodyFilter = MultisegmentView.new
    @bodyFilter.addButton("Sed", Model.filterOptions[:sedan]) { |state| applyFilter(sedan: state) } if availableOptions[:sedan]
    @bodyFilter.addButton("Wag", Model.filterOptions[:wagon]) { |state| applyFilter(wagon: state) } if availableOptions[:wagon]
    @bodyFilter.addButton("Hat", Model.filterOptions[:hatch]) { |state| applyFilter(hatch: state) } if availableOptions[:hatch]

    @fuelFilter = MultisegmentView.new
    @fuelFilter.addButton("Gas", Model.filterOptions[:gas]) { |state| applyFilter(gas: state) } if availableOptions[:gas]
    @fuelFilter.addButton("Di", Model.filterOptions[:diesel]) { |state| applyFilter(diesel: state) } if availableOptions[:diesel]

    self.toolbarItems = [
      UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemFlexibleSpace, target:nil, action:nil),
      UIBarButtonItem.alloc.initWithCustomView(@transmissionFilter),
      UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemFixedSpace, target:nil, action:nil),
      UIBarButtonItem.alloc.initWithCustomView(@bodyFilter),
      UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemFixedSpace, target:nil, action:nil),
      UIBarButtonItem.alloc.initWithCustomView(@fuelFilter),
      UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemFlexibleSpace, target:nil, action:nil),      
    ]    
  end
  
  def numberOfSectionsInTableView(tview)
    @modsByBody.count > 0 ? @modsByBody.count : 1
  end

  def tableView(tv, numberOfRowsInSection:section)
    return 0 if section >= @modsByBody.count
    bodyKey = modsByBody.keys[section]
    @modsByBody[bodyKey].count
  end

  def tableView(tview, titleForHeaderInSection:section)
    bodyKey = modsByBody.keys[section]
    Static.body_names[bodyKey]
  end

  def tableView(tview, titleForFooterInSection:section)
    if section == tableView.numberOfSections - 1
      hiddenModsCount = mods.count - filteredMods.count
      if @modsByBody.count == 0
        "#{hiddenModsCount} models available\n Relax the filter settings to view it"
      else
        hiddenModsCount > 0 ? "There are also #{hiddenModsCount} models hidden" : nil
      end
    end
  end

  def tableView(table, cellForRowAtIndexPath:indexPath)
    bodyKey = modsByBody.keys[indexPath.section]
    mod = modsByBody[bodyKey][indexPath.row]

    cell = table.dequeueReusableCell
    cell.textLabel.text = mod.nameWithVersion
    cell.accessoryType = Model.currentMods.include?(mod) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone
    cell
  end

  def tableView(table, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)

    bodyKey = modsByBody.keys[indexPath.section]
    mod = modsByBody[bodyKey][indexPath.row]

    cell = tableView.cellForRowAtIndexPath(indexPath)
    cell.toggleCheckmark
    mod.toggle
  end
  
  private
  
  def applyFilter(options = {})
    Model.filterOptions = Model.filterOptions.merge(options) if options.any?
    self.filteredMods = Model.filterOptions.empty? ? mods : mods.select do |mod|
      next false if Model.filterOptions[:at] && mod.automatic?
      next false if Model.filterOptions[:mt] && mod.manual?
      next false if Model.filterOptions[:sedan] && mod.sedan?
      next false if Model.filterOptions[:hatch] && mod.hatch?
      next false if Model.filterOptions[:wagon] && mod.wagon?
      next false if Model.filterOptions[:gas] && mod.gas?
      next false if Model.filterOptions[:diesel] && mod.diesel?
      next true
    end
    self.modsByBody = filteredMods.group_by { |m| m.body }    
    tableView.reloadData
  end
end