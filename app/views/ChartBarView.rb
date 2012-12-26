class ChartBarView < UIView  
  attr_accessor :comparisionItem
  attr_delegated 'comparisionItem', :mod, :mods, :index, :comparision

  TitleLM = 4

  ModelTitleFS = 15.0
  ModelTitleH = KKLineHeightFromFontSize(ModelTitleFS)
  ModelTitleBM = 0
  ModelTitleRM = 4
  ModTitleFS = 14.0
  ModTitleH = KKLineHeightFromFontSize(ModTitleFS)
  ModTitleBM = 0
    
  BarFS = 13.0
  BarH = KKLineHeightFromFontSize(BarFS)
  BarFH = BarH + 0
  BarLM = TitleLM
  BarRM = 1
  BarValueRM = BarFS / 2
  BarMaxValueRM = BarValueRM + 2
  BarMinW = 40
  
  WideBarLabelW = 250
  WideBarLM = 5
  WideBarRM = 10
  UltraWideBarLabelW = 350
  
  ItemBM = 4
  LastItemBM = ItemBM * 2

  def initWithFrame(frame)
    super
    self.opaque = true
    self.backgroundColor = UIColor.whiteColor # ES.patternColor("bg-chart")
    self.contentMode = UIViewContentModeRedraw
    self
  end

  def drawRect(rect)
    renderingMode = self.class.renderingMode
    renderingMode == :wide || renderingMode == :ultraWide ? drawWide(rect) : drawNarrow(rect)
  end
  
  private

  def drawWide(rect)
    context = UIGraphicsGetCurrentContext()
    headerHeight = 0

    modTitleOptions = comparision.containsOnlyBodyParams?? Mod::NameBodyVersion : Mod::NameBodyEngineVersion
    modTitle = mod.modName(modTitleOptions)
    case self.class.renderingMode when :wide
      labelWidth = WideBarLabelW
      labelHeight = ModTitleH
      if comparisionItem.firstForModel?
        headerHeight = ModelTitleH + ModelTitleBM
        modelTitleRect = CGRectMake(0, 0, labelWidth, ModelTitleH)
        ES.drawString mod.model.name, inRect:modelTitleRect, withColor:UIColor.blackColor, font:ES.boldFont(ModelTitleFS), alignment:UITextAlignmentRight 
      end
      labelRect = CGRectMake(0, headerHeight, labelWidth, labelHeight)
      ES.drawString modTitle, inRect:labelRect, withColor:UIColor.darkGrayColor, font:ES.mainFont(ModTitleFS), alignment:UITextAlignmentRight
    when :ultraWide
      labelWidth = UltraWideBarLabelW
      labelHeight = ModelTitleH
      labelRect = CGRectMake(0, headerHeight, labelWidth, labelHeight)
      ES.drawInRect labelRect, stringsSpecs:[
        [mod.model.name, UIColor.blackColor, ES.boldFont(ModelTitleFS), ModelTitleRM],
        [modTitle, UIColor.grayColor, ES.mainFont(ModTitleFS), ModelTitleRM]
      ], alignment:UITextAlignmentRight
    end
    
    pixelRange = bounds.width - labelWidth - BarMinW - WideBarRM
    textColor = UIColor.whiteColor
    textFont = ES.mainFont(BarFS)
    barsOffset = (labelHeight - BarH) / 2 + headerHeight
    comparision.params.each do |param|
      index = comparision.params.index(param)
      value = mod[param]
      barWidth = (value - comparision.minValueFor(param)) * pixelRange / comparision.rangeFor(param) + BarMinW
      rect = CGRectMake(labelWidth + WideBarLM, barsOffset + index * BarFH, barWidth, BarH)
      isWiderThanBounds = rect.width >= bounds.width - labelWidth
      maxTextWidth = rect.width - (isWiderThanBounds ? BarMaxValueRM : BarValueRM)
      bgColors = self.class.colors[index.remainder(self.class.colors.count)]
      textRect = CGRectMake(rect.x, rect.y, maxTextWidth, rect.height)
      
      ES.drawRect rect, inContext:context, withGradientColors:bgColors, cornerRadius:3
      ES.drawString param.formattedValue(value), inRect:textRect, withColor:textColor, font:textFont, alignment:UITextAlignmentRight
    end    
  end

  def drawNarrow(rect)
    context = UIGraphicsGetCurrentContext()
    maxBarWidth = bounds.width - BarLM - BarRM

    labelRect = CGRectMake(TitleLM, 0, maxBarWidth, ModelTitleH)
    modTitleOptions = comparision.containsOnlyBodyParams?? Mod::NameBodyVersion : Mod::NameBodyEngineVersion
    modTitle = mod.modName(modTitleOptions)
    
    if iphone? && KK.portrait? 
      modelTitleWidth = mod.model.name.sizeWithFont(ES.boldFont(ModelTitleFS)).width
      modTitleWidth = modTitle.sizeWithFont(ES.mainFont(ModelTitleFS)).width
      fullWidth = modelTitleWidth + modelTitleWidth + ModelTitleRM * 2
      extraWidth = fullWidth - labelRect.width
      modTitleFSFix = extraWidth > 0 ? [extraWidth / 25.0, 2.0].min.round_to(0.25) : 0
    else
      modTitleFSFix = 0
    end

    ES.drawInRect labelRect, stringsSpecs:[
      [mod.model.name, UIColor.blackColor, ES.boldFont(ModelTitleFS - modTitleFSFix), ModelTitleRM],
      [modTitle, UIColor.grayColor, ES.mainFont(ModTitleFS - modTitleFSFix), 0]
    ]

    pixelRange = maxBarWidth - BarMinW
    barsOffset = ModelTitleH + ModelTitleBM
    textFont = ES.mainFont(BarFS)
    comparision.params.each do |param|
      index = comparision.params.index(param)
      value = mod[param] || 0
      barWidth = (value - comparision.minValueFor(param)) * pixelRange / comparision.rangeFor(param) + BarMinW
      rect = CGRectMake(BarLM, barsOffset + index * BarFH, barWidth, BarH)
      isWiderThanBounds = rect.width >= maxBarWidth
      maxTextWidth = rect.width - (isWiderThanBounds ? BarMaxValueRM : BarValueRM)
      textRect = CGRectMake(rect.x, rect.y, maxTextWidth, rect.height)
      bgColors = self.class.colors[index.remainder(self.class.colors.count)]
            
      ES.drawRect rect, inContext:context, withGradientColors:bgColors, cornerRadius:3
      ES.drawString param.formattedValue(value), inRect:textRect, withColor:'white', font:textFont, alignment:UITextAlignmentRight
    end    
  end

  def self.renderingMode
    case 
      when iphone? then :narrow
      when ES.landscape? && KK.app.delegate.chartController.fullScreen? then :ultraWide
      when ES.landscape? || KK.app.delegate.chartController.fullScreen? then :wide
      else :narrow
    end
  end
  
  def self.colors
    @colors ||= Metadata.colors.map do |h,s,b|
      [ES.hsb(h, s - 20, b + 5), ES.hsb(h, s + 10, b - 5)]
    end
  end

  def self.heightForComparisionItem(item)
    height = 0
    height += ChartBarView::ModelTitleH + ChartBarView::ModelTitleBM if renderingMode == :narrow || renderingMode == :wide && item.firstForModel?
    height += item.comparision.params.count * ChartBarView::BarFH
    height += item.lastForModel?? LastItemBM : ItemBM
  end


  class TableCell < UITableViewCell
    attr_accessor :barView
    attr_delegated 'barView', :comparisionItem
  
    def initWithStyle(style, reuseIdentifier:identifier)
      super UITableViewCellStyleValue1, reuseIdentifier:identifier
      self.barView = ChartBarView.alloc.initWithFrame(CGRectMake(0, 0, contentView.bounds.width, contentView.bounds.height))
      self.barView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
      self.contentView.addSubview barView
      self
    end
  end
end
