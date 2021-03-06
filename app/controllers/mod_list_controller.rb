class ModListController < UIViewController
  attr_accessor :model, :mods, :modsByBody, :filteredMods, :tableView, :toolbar
  attr_accessor :selectedMod, :photoControllers

  @@photosViewCount = 0

  def initialize(model = nil)
    self.model = model
    self.mods = model.mods
    self.title = model.nameWithApostrophe
    self.photoControllers = {}
    # self.canDisplayBannerAds = KK.app.delegate.showsBannerAds?
    navigationItem.backBarButtonItem = KK.textBBI("Models")
    navigationItem.rightBarButtonItem = KK.imageBBI("bi-filter", target:self, action:'showFilterPane')
    Disk.addObserver(self, forKeyPath:"filterOptions", options:false, context:nil)
    Disk.addObserver(self, forKeyPath:"currentMods", options:NO, context:nil)
    Disk.addObserver(self, forKeyPath:"favorites", options:NO, context:nil)
  end

  def dealloc
    Disk.removeObserver(self, forKeyPath:"filterOptions")
    Disk.removeObserver(self, forKeyPath:"currentMods")
    Disk.removeObserver(self, forKeyPath:"favorites")
  end

  def observeValueForKeyPath(keyPath, ofObject:object, change:change, context:context)
    return if propertyObservingDisabled?(keyPath)
    case keyPath 
    when 'filterOptions'
      applyFilter if isViewVisible
    when 'currentMods'
      tableView.reloadData
    when 'favorites'
      tableView.reloadRowsAtIndexPaths [NSIndexPath.indexPathForRow(0, inSection: 0)], withRowAnimation:UITableViewRowAnimationFade unless @dontTrackFavorites
    end
  end


  def viewDidLoad
    self.tableView = setupInnerTableViewWithStyle(UITableViewStylePlain)
  end

  def viewWillAppear(animated) super
    applyFilter
    ## disabled: refreshing data will break the offset for some reason
    ## tableView.contentOffset = CGPointMake(0, DEFAULT_ROW_HEIGHT) if tableView.contentOffset.y == 0
    ## tableView.contentOffset = CGPointMake(0, -DEFAULT_ROW_HEIGHT + 20) if tableView.contentOffset.y == -64 # hack
    scrollToMod(selectedMod, animated:NO) if selectedMod
  end
  
  def didReceiveMemoryWarning  
    photoControllers.each do |section, controller|
      photoControllers[section] = nil unless controller && controller.viewLoaded? && controller.view.window
    end    
    super
  end


  def numberOfSectionsInTableView(tv)
    modsByBody.count + 1
  end

  def tableView(tv, numberOfRowsInSection:section)
    case section when 0
      1
    else
      modsByBody[ modsByBody.keys[section - 1] ].count
    end
  end

  def tableView(tv, titleForHeaderInSection:section)
    case section when 0
      nil
    else
      section_body_key = modsByBody.keys[section - 1]
      if section_body_key.include?('.')
        sample_mod = mods.detect { |mod| mod.body == section_body_key }
        sample_mod.capitalBodyName
      else
        Metadata.parameterTranslations['body_capitalized'][ section_body_key ]
      end
    end
  end

  def tableView(tv, titleForFooterInSection:section)
    case section when tableView.numberOfSections - 1
      hiddenModsCount = mods.count - filteredMods.count
      if modsByBody.count == 0 && !mods.empty?
        "All #{hiddenModsCount} #{"model".pluralizeFor(hiddenModsCount)} are filtered out"
      else
        hiddenModsCount > 0 ? "There are also #{hiddenModsCount} #{"model".pluralizeFor(hiddenModsCount)} hidden" : nil
      end
    end
  end

  def tableView(tv, cellForRowAtIndexPath:indexPath)
    case indexPath.section when 0
      cell = tv.dequeueReusableCell id:'Action', style:UITableViewCellStyleDefault
      cell.textLabel.textColor = Configuration.tintColor      
      if Disk.favorites.include?(model)
        cell.textLabel.text = "Remove from Favorites"
        cell.accessoryView = UIImageView.alloc.initWithImage(KK.templateImage('bar-star-full'))
      else
        cell.textLabel.text = "Add to Favorites"
        cell.accessoryView = UIImageView.alloc.initWithImage(KK.templateImage('bar-star'))
      end
    else
      bodyIndex = indexPath.section - 1
      mod = modsByBody[ modsByBody.keys[bodyIndex] ][indexPath.row]
      cell = tv.dequeueReusableCell klass:CheckmarkCell, accessoryType:UITableViewCellAccessoryDetailButton
      cell.toggleLeftCheckmarkAccessory(mod.selected?)
      cell.textLabel.text = mod.modName(Mod::NameEngineVersion)
    end
    cell
  end

  def tableView(tv, didSelectRowAtIndexPath:indexPath)
    case indexPath.section when 0
      KK.trackEvent "favorites-toggle", model
      Disk.toggleInFavorites(model)
    else      
      mod = modsByBody[ modsByBody.keys[indexPath.section - 1] ][indexPath.row]
      withoutObserving('currentMods') { mod.select! }

      KK.animateWithDuration 0.3 do
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
        cell = tableView.cellForRowAtIndexPath(indexPath)
        cell.toggleLeftCheckmarkAccessory(mod.selected?)
      end
    end
  end

  def tableView(tv, accessoryButtonTappedForRowWithIndexPath:indexPath)
    mod = modsByBody[ modsByBody.keys[indexPath.section - 1] ][indexPath.row]
    ModViewController.showFor self, withMod:mod
  end

  def tableView(tv, viewForHeaderInSection:section)
    return nil if section == 0
    header = ModListSectionHeaderView.alloc.initWithFrame(CGRectMake 0, 0, view.frame.width, ModListSectionHeaderView.sectionHeight)
    header.title = tableView(tv, titleForHeaderInSection:section)
    header.sectionIndex = section
    header.buttonAction = 'showPhotosForSection:'
    header.buttonTarget = self
    header
  end
  
  def tableView(tv, heightForHeaderInSection:section)
    return 0 if section == 0
    ModListSectionHeaderView.sectionHeight
  end

  def showPhotosForSection(section)
    @@photosViewCount += 1

    if @@photosViewCount >= SHOW_AD_AFTER_PHOTO_VIEWS
      willShowAd = requestInterstitialAdPresentation
      @@photosViewCount = 0 if willShowAd
    end
    
    unless willShowAd
      mod = modsByBody[ modsByBody.keys[section - 1] ].first
      photoControllers[section] ||= ModelPhotosController.new(mod.model, mod.bodyVersionOrName)
      if KK.iphone?
        navigationController.pushViewController photoControllers[section], animated:true
      else
        presentNavigationController photoControllers[section], presentationStyle:UIModalPresentationFullScreen
      end    
    end
  end

  def applyFilter(options = {})
    opts = Disk.filterOptions
    @filteredMods = opts.empty? ? mods : mods.select do |mod|
      next false if opts[:at] == false && mod.automatic?
      next false if opts[:mt] == false && mod.manual?
      next false if opts[:sedan] == false && mod.sedan?
      next false if opts[:hatch] == false && mod.hatch?
      next false if opts[:wagon] == false && mod.wagon?
      next false if opts[:gas] == false && mod.gas?
      next false if opts[:diesel] == false && mod.diesel?
      next true
    end
    @modsByBody = @filteredMods.group_by { |m| m.body }
    tableView.reloadData
  end

  def showFilterPane
    @filterController ||= ModListFilterController.new
    if KK.iphone?
      presentNavigationController @filterController
    else
      @filterController.popover = presentPopoverController @filterController, fromBarItem:navigationItem.rightBarButtonItem
    end
  end

  def scrollToMod(mod, animated:animated)
    modsWithSuchBody = modsByBody[mod.body]
    if modsWithSuchBody
      modIndex = modsWithSuchBody.index(mod)
      if modIndex
        bodyIndex = modsByBody.keys.index(mod.body)
        indexPath = NSIndexPath.indexPathForRow(modIndex, inSection: bodyIndex + 1)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPositionTop, animated:animated)
      end
    end
  end  

  def screenKey
    { model: model.key }
  end    
end
