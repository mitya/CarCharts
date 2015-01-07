module KK::Common
  def app
    UIApplication.sharedApplication
  end

  def defaults
    NSUserDefaults.standardUserDefaults
  end

  def indexPath(section, row)
    NSIndexPath.indexPathForRow(row, inSection: section)
  end

  def sequentialIndexPaths(section, firstRow, lastRow)
    return [] if firstRow > lastRow
    firstRow.upto(lastRow).map { |row| indexPath(section, row) }
  end

  def ptr(type = :object)
    Pointer.new(type)
  end

  def documentsURL
    NSFileManager.defaultManager.URLsForDirectory(NSDocumentDirectory, inDomains:NSUserDomainMask).first
  end    
  
  def navigationForController(controller, withDelegate:delegate)
    UINavigationController.alloc.initWithRootViewController(controller).tap do |navigation|
      navigation.delegate = delegate
    end
  end
end

KK.extend(KK::Common)