class AppDelegate
  attr_accessor :window, :navigationController
  
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    self.navigationController = UINavigationController.alloc.initWithRootViewController(ParamsChartController.alloc.init)
    navigationController.delegate = self

    self.window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    window.backgroundColor = UIColor.whiteColor
    window.rootViewController = navigationController
    window.makeKeyAndVisible
    
    return true
  end
end

class MainViewController < UITableViewController
  attr_accessor :data
  
  def viewDidLoad
    super
    self.title = "Главное окно"
    
    dataPath = NSBundle.mainBundle.pathForResource("final-models.bin", ofType:"plist")
    self.data = NSMutableArray.alloc.initWithContentsOfFile(dataPath)
  end
  
  def tableView(tv, numberOfRowsInSection:section)
    return data.count
  end
  
  def tableView(tv, cellForRowAtIndexPath:ip)  
    unless cell = tv.dequeueReusableCellWithIdentifier("cell")
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:"cell")
      cell.selectionStyle = UITableViewCellSelectionStyleNone
      cell.textLabel.adjustsFontSizeToFitWidth = true
    end
    
    item = data[ip.row]
    cell.textLabel.text = item['key']
    return cell
  end
end

class ModelManager
  attr_accessor :modifications, :modifications_index, :metadata

  def brand_names
    @metadata['brand_names']
  end

  def model_names
    @metadata['model_names']
  end

  def body_names
    @metadata['body_names']
  end
  
  def branded_model_name_for(model_key)
    brand_key = model_key.split('--').first
    brand_name = brand_names[brand_key]
    model_name = model_names[model_key]
    "#{brand_name} #{model_name}"
  end
  
  def modification_for(key)
    modifications_index[key]
  end
  
  def self.instance
    @instance
  end
  
  def self.load
    instance.modifications = NSMutableArray.alloc.initWithContentsOfFile(NSBundle.mainBundle.pathForResource("modifications.bin", ofType:"plist"))
    instance.metadata = NSMutableDictionary.alloc.initWithContentsOfFile(NSBundle.mainBundle.pathForResource("metadata.bin", ofType:"plist"))
    instance.modifications_index = Hash[ instance.modifications.map { |hash| [hash['key'], hash] } ]
  end
  
  @instance = new
end

Model = ModelManager.instance

class ParamsChartController < UITableViewController
  attr_accessor :models, :params, :data

  def viewDidLoad
    super
    
    ModelManager.load
    
    self.params = ['max_power']
    self.models = [
      "ford--focus--2011--hatch_5d---2.0i-150ps-AMT-FWD", 
      "opel--astra--2010--hatch_5d---1.4i-140ps-AT-FWD",
      "volkswagen--golf--2009--hatch_5d---1.4i-122ps-AMT-FWD",
      "honda--civic--2012--sedan---1.8i-142ps-AT-FWD"
    ]
    
    self.tableView.rowHeight = 25
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone
    # self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine
    # self.tableView.separatorColor = UIColor.lightGrayColor
  end

  def tableView(tv, numberOfRowsInSection:section)
    return models.count
  end
  
  def tableView(tv, cellForRowAtIndexPath:ip)
    unless cell = tv.dequeueReusableCellWithIdentifier("barCell")
      # cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:"cell")
      cell = BarTableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:"barCell")
      # cell.selectionStyle = UITableViewCellSelectionStyleNone
      # cell.textLabel.adjustsFontSizeToFitWidth = true
    end
    
    cell.model = Model.modification_for(models[ip.row])
    return cell
  end
  
end


class BarTableViewCell < UITableViewCell
  attr_accessor :model, :barView
  
  def initWithStyle(style, reuseIdentifier:reuseIdentifier)
  	if super(UITableViewCellStyleDefault, reuseIdentifier:reuseIdentifier)
      barFrame = CGRectMake(0, 0, contentView.bounds.size.width, contentView.bounds.size.height)
      self.barView = BarView.alloc.initWithFrame(barFrame)
      barView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
      contentView.addSubview(barView)
    end
  	return self
  end
  
  def model=(object)
    @model = object
    barView.model = object
  end
end

class BarView < UIView
  attr_accessor :model
    
  def initWithFrame(frame)
  	if super(frame)
  		self.opaque = true
  		self.backgroundColor = UIColor.whiteColor
    end
  	return self
  end

  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()
    
    value = model['max_power'].to_f
    width = value * bounds.size.width / 250
    rect = CGRectMake(0, 5, width, 20)
        
    # CGContextSetLineWidth(context, 20)
    # CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor)
    # CGContextMoveToPoint(context, 0, 15)
    # CGContextAddLineToPoint(context, width, 15)
    # CGContextStrokePath(context)

    # CGContextSetFillColorWithColor(context, UIColor.redColor.CGColor)
    # CGContextFillRect(context, bar)
    
    drawGradientRect(context, rect, UIColor.redColor, UIColor.yellowColor)
    
    model_key = model['key'].split('--').first(2).join('--')
    model_name = Model.branded_model_name_for(model_key)
        
    UIColor.blackColor.set
    actualFontSize = Pointer.new(:float)
		model_name.drawAtPoint CGPointMake(5, 8), forWidth:bounds.size.width - 5, 
      withFont:UIFont.systemFontOfSize(12), minFontSize:10, actualFontSize:actualFontSize,
      lineBreakMode:UILineBreakModeTailTruncation, baselineAdjustment:UIBaselineAdjustmentAlignBaselines
  end
  
  def drawGradientRect(context, rect, color1, color2)
    # locationsPtr = Pointer.new(:float, 2)
    # locationsPtr[0] = 0.0
    # locationsPtr[1] = 1.0

    colorSpace = CGColorSpaceCreateDeviceRGB()
    colors = [color1.CGColor, color2.CGColor]
    gradient = CGGradientCreateWithColors(colorSpace, colors, nil)
    
    startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))
    endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))
 
    CGContextSaveGState(context)
    CGContextAddRect(context, rect)
    CGContextClip(context)
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0)
    CGContextRestoreGState(context)
 
    # CGGradientRelease(gradient)
    # CGColorSpaceRelease(colorSpace)    
  end
end
