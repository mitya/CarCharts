UIViewAutoresizingFlexibleAllMargins = UIViewAutoresizingFlexibleLeftMargin | 
                                       UIViewAutoresizingFlexibleRightMargin | 
                                       UIViewAutoresizingFlexibleTopMargin | 
                                       UIViewAutoresizingFlexibleBottomMargin
UISafariUA = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
UIToolbarHeight = 44.0


class UIColor
  def hsbString
    hue, saturation, brightness, alpha = Pointer.new(:float), Pointer.new(:float), Pointer.new(:float), Pointer.new(:float)
    success = getHue(hue, saturation:saturation, brightness:brightness, alpha:alpha)
    success ? "hsba(%.2f, %.2f, %.2f, %.2f)" % [hue, saturation, brightness, alpha].map(&:value) : nil
  end
    
  def rgbString
    red, green, blue, alpha = Pointer.new(:float), Pointer.new(:float), Pointer.new(:float), Pointer.new(:float)
    success = getRed(red, green:green, blue:blue, alpha:alpha)
    success ? "rgba(%.2f, %.2f, %.2f, %.2f)" % [red, green, blue, alpha].map(&:value) : nil
  end
    
  def whiteLevelString
    white, alpha = Pointer.new(:float), Pointer.new(:float)
    success = getWhite(white, alpha:alpha)
    success ? "white(%.2f, alpha=%.2f)" % [white, alpha].map(&:value) : nil
  end
  
  def inspect2
    rgbString || hsbString || whiteLevelString
  end
end


class UIFont
  def inspect
    "#<#{self.class.name}:'#{fontName}' #{pointSize}/#{lineHeight}>"
  end
end


class UIView
  def xdBorder(color = UIColor.redColor)
    KK.set_border(self, color)
  end
  
  def setRoundedCornersWithRadius(radius, width:width, color:color)
    KK.setRoundedCornersForView(self, withRadius:radius, width:width, color:color)
  end
end

module ObserverDisabling
  def withoutObserving(property)
    notificationTumblers[property] = false
    yield
    notificationTumblers[property] = true
  end  
  
  def propertyObservingDisabled?(keyPath)
    notificationTumblers[keyPath] == false
  end
  
  def notificationTumblers
    @notificationTumblers ||= {}
  end
end


class UIViewController
  include GlobalHelpers
  
  def self.autorotationPolicy
    @autorotationPolicy
  end
  
  def self.autorotation(policy)
    @autorotationPolicy = policy
    def shouldAutorotateToInterfaceOrientation(interfaceOrientation)
      self.class.autorotationPolicy
    end    
  end
  
  def self.new(*args)
    alloc.init.tap { |this| this.send(:initialize, *args) if this.respond_to?(:initialize, true) }
  end

  def setupInnerTableViewWithStyle(tableViewStyle, options = nil)
    offset = options ? options[:offset].to_f : 0.0
    delegate = options && options.include?(:delegate) ? options[:delegate] : self
    screen = UIScreen.mainScreen.bounds
    bounds = CGRectMake(screen.x, screen.y + offset, screen.width, screen.height - offset)
    
    tableView = UITableView.alloc.initWithFrame(bounds, style:tableViewStyle)
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
    tableView.dataSource = delegate
    tableView.delegate = delegate
    
    view.addSubview(tableView)
    
    tableView
  end
  
  def realWidth
    controller = tabBarController || navigationController || self
    controller.view.bounds.width
  end
  
  def isViewVisible
    isViewLoaded && view.window
  end
  
  def presentNavigationController(controller, options = {})
    KK.trackControllerView(controller)
    controller.presented_modally = true if controller.respond_to?('presented_modally=')
    navigation = KK.navigationForController(controller, withDelegate:NIL)
    navigation.modalPresentationStyle = options[:presentationStyle] || UIModalPresentationFullScreen
    navigation.modalTransitionStyle = options[:transitionStyle] || UIModalTransitionStyleCoverVertical
    presentViewController navigation, animated:(options[:animated].nil?? YES : options[:animated]), completion:NIL
  end  
  
  def presentPopoverController(controller, options = {})
    KK.trackControllerView(controller)
    navigation = KK.navigationForController(controller, withDelegate:NIL)
    popover = UIPopoverController.alloc.initWithContentViewController(navigation)
    if barItem = options[:fromBarItem]
      popover.presentPopoverFromBarButtonItem barItem, permittedArrowDirections:UIPopoverArrowDirectionAny, animated:YES
    end
    popover
  end  
  
  def dismissSelfAnimated(animated = true)
    if respond_to?(:popover) && popover
      popover.dismissPopoverAnimated(animated)
    elsif presentingViewController
      presentingViewController.dismissModalViewControllerAnimated(animated, completion:nil)
    elsif navigationController
      navigationController.popViewControllerAnimated(animated)
    end    
  end
  
  def appDelegate
    KK.app.delegate
  end
  
  include ObserverDisabling
end

class UITableView
  def dequeueReusableCell(options = nil, &block)
    id = options && options[:id] || "cell"
    klass = options && options[:klass] || UITableViewCell
    style = options && options[:style] || UITableViewCellStyleDefault
    
    cell = dequeueReusableCellWithIdentifier(id) || klass.alloc.initWithStyle(style, reuseIdentifier:id).tap do |cell|
      cell.accessoryType = options[:accessoryType] if options && options[:accessoryType]
      cell.selectionStyle = options[:selectionStyle] if options && options[:selectionStyle]
      block.call(cell) if block
    end
  end
  
  # def reusableCellWith(options = nil)
  #   cell = dequeueReusableCell(options)
  #   yield cell if block_given?
  #   cell
  # end
  
  def reloadVisibleRows
    reloadRowsAtIndexPaths(indexPathsForVisibleRows, withRowAnimation:UITableViewRowAnimationNone)
  end
end


class UITableViewCell
  def toggleCheckmarkAccessory(value = nil)
    value = accessoryType != UITableViewCellAccessoryCheckmark if value == nil
    self.accessoryType = value ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone
  end
end


class UITableViewController
  DefaultTableViewStyleForRubyInit = UITableViewStylePlain
  
  def self.initAsRubyObject(*args)
    style = const_get(:DefaultTableViewStyleForRubyInit)    
    alloc.initWithStyle(style).tap { |this| this.send(:initialize, *args) }
  end
  
  def self.new(*args)
    initAsRubyObject(*args)
  end  
end


class UITabBarController
  def setTabBarHidden(hidden, animated:animated)
    duration = animated ? 0.2 : 0
    contentHeight = hidden ? view.bounds.height : view.bounds.height - tabBar.bounds.height
    tabBar.translucent = hidden
    completion = lambda { |_| tabBar.hidden = YES if hidden == YES }
    tabBar.hidden = NO if hidden == NO
    KK.animateWithDuration(duration, completion:completion) do
      view.subviews.each do |view|
        if view.isKindOfClass(UITabBar)
          view.frame = CGRectMake(view.frame.origin.x, contentHeight, view.frame.size.width, view.frame.size.height)
        else 
          view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, contentHeight)
        end
      end
    end    
  end
end
