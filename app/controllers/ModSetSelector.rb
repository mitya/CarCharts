class SelectModSetController < UITableViewController
  attr_accessor :sets

  def viewDidLoad
    self.title = "Select Model Set"
    navigationItem.leftBarButtonItem = ES.systemBBI(UIBarButtonSystemItemCancel, target:self, action:'cancel')
  end

  def shouldAutorotateToInterfaceOrientation(interfaceOrientation)
    true
  end

  def tableView(tv, numberOfRowsInSection:section)
    reloadSets
    @sets.count
  end

  def tableView(tv, cellForRowAtIndexPath:indexPath)
    set = @sets[indexPath.row]
    cell = tv.dequeueReusableCell(klass: DSBadgeViewCell)
    cell.textLabel.text = set.name
    cell.badgeText = set.modCount
    cell
  end

  def tableView(tv, didSelectRowAtIndexPath:indexPath)
    set = @sets[indexPath.row]
    set.mods = Disk.currentMods
    tableView.deselectRowAtIndexPath indexPath, animated:YES    
    dismissModalViewControllerAnimated true, completion:NIL
  end

  ####
  
  def reloadSets
    @sets = ModSet.all
  end
  
  def cancel
    dismissModalViewControllerAnimated true, completion:NIL
  end
end