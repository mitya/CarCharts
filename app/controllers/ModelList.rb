class ModelsController < UITableViewController
  attr_accessor :category
  attr_accessor :searchBar
  
  def initialize(models)
    @initialModels = models
    self.title = "Models"
  end

  def viewDidLoad
    @filteredModels = @initialModels
    
    self.searchBar = UISearchBar.alloc.initWithFrame(CGRectMake(0, 0, view.bounds.width, DSToolbarHeight)).tap do |searchBar|
      searchBar.autocorrectionType = UITextAutocorrectionTypeNo
      searchBar.placeholder = "Search"
      searchBar.delegate = self
      tableView.tableHeaderView = searchBar
      tableView.contentOffset = CGPointMake(0, searchBar.frame.height)
      tableView.addSubview ES.grayTableViewTop
    end
    
    self.searchDisplayController = UISearchDisplayController.alloc.initWithSearchBar(@searchBar, contentsController:self).tap do |sdc|
      sdc.delegate = sdc.searchResultsDataSource = sdc.searchResultsDelegate = self
    end
    
    navigationItem.backBarButtonItem = ES.textBBI("Back")
  end

  def viewWillAppear(animated)
    super
    activeTableView = searchDisplayController.isActive ? searchDisplayController.searchResultsTableView : tableView
    activeTableView.reloadVisibleRows
  end

  def shouldAutorotateToInterfaceOrientation(interfaceOrientation)
    true
  end
  
  ####

  def tableView(tv, numberOfRowsInSection:section)
    @filteredModels.count
  end

  def tableView(table, cellForRowAtIndexPath:indexPath)  
    model = @filteredModels[indexPath.row]
    modelSelectedModsCount = model.selectedModsCount

    cell = table.dequeueReusableCell(klass: DSBadgeViewCell) { |cl| cl.accessoryType = UITableViewCellAccessoryDisclosureIndicator }
    cell.text = model.name
    cell.badgeText = modelSelectedModsCount.to_s if modelSelectedModsCount > 0
    cell
  end

  def tableView(table, didSelectRowAtIndexPath:indexPath)
    model = @filteredModels[indexPath.row]
    tableView.deselectRowAtIndexPath indexPath, animated:YES
    navigationController.pushViewController ModsController.new(model), animated:YES
  end
  
  ####

  def searchDisplayController(ctl, willHideSearchResultsTableView:tbl)
    loadDataForSearchString("")
    tableView.reloadVisibleRows
  end
  
  def searchDisplayController(controller, shouldReloadTableForSearchString:newSearchString)
    currentModels = @filteredModels
    loadDataForSearchString(newSearchString)
    currentModels != @filteredModels
  end
  
  ####
  
  def loadDataForSearchString(newSearchString)
    ES.benchmark "Model Search" do
      collectionToSearch = newSearchString.start_with?(@currentSearchString) ? @filteredModels : @initialModels
      @filteredModels = newSearchString.empty? ? @initialModels : Model.modelsForText(newSearchString, inCollection:collectionToSearch)
      @currentSearchString = newSearchString
    end
  end
end
