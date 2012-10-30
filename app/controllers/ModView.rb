class ModController < UITableViewController
  DefaultTableViewStyleForRubyInit = UITableViewStyleGrouped
  attr_accessor :mod

  def initialize(mod)
    self.mod = mod
    self.hidesBottomBarWhenPushed = YES
  end

  def viewDidLoad
    self.title = mod.model.name
    self.tableView.tableHeaderView = ES.tableViewFooterLabel(mod.basicName)
  end

  def shouldAutorotateToInterfaceOrientation(interfaceOrientation)
    true
  end

  ####

  def systemSectionIndex
    @systemSectionIndex ||= Parameter.groupKeys.count
  end

  def numberOfSectionsInTableView(tv)
    Parameter.groupKeys.count + 1
  end

  def tableView(tv, numberOfRowsInSection:section)
    return 1 if section == systemSectionIndex
    
    groupKey = Parameter.groupKeys[section]
    Parameter.parametersForGroup(groupKey).count
  end

  def tableView(tv, titleForHeaderInSection:section)
    return nil if section == systemSectionIndex
    
    groupKey = Parameter.groupKeys[section]
    Parameter.nameForGroup(groupKey)
  end

  def tableView(tv, cellForRowAtIndexPath:indexPath)
    if indexPath.section == systemSectionIndex
      cell = tv.dequeueReusableCell(id: 'Action', style:UITableViewCellStyleDefault) do |cell|
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator
        cell.textLabel.text = "Photos"
        cell.imageView.image = UIImage.imageNamed("google_icon")
      end  
    else
      parameter = Parameter.parametersForGroup( Parameter.groupKeys[indexPath.section] )[indexPath.row]
      cell = tv.dequeueReusableCell(style: UITableViewCellStyleValue1) { |cl| cl.selectionStyle = UITableViewCellSelectionStyleNone }
      cell.textLabel.text = parameter.name
      cell.textLabel.font = ES.boldFont(parameter.long?? 16.0 : 17.0)
      cell.detailTextLabel.text = @mod.fieldTextFor(parameter)
    end
    cell
  end
  
  def tableView(tv, didSelectRowAtIndexPath:indexPath)
    tv.deselectRowAtIndexPath(indexPath, animated:YES)
    if indexPath.section == systemSectionIndex && indexPath.item == 0
      navigationController.pushViewController ModelPhotosController.new(mod.model), animated:YES
    end
  end  
end