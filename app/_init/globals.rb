YES = true
NO = false
NULL = nil
ZERO = 0
THIN_SPACE = ' '
HAIR_SPACE = ' '
DEFAULT_ROW_HEIGHT = 44.0
TWO_LINE_ROW_HEIGHT = 64.0
DEBUG = NSBundle.mainBundle.objectForInfoDictionaryKey('CCDebugMode') == true
SIMULATOR = UIDevice.currentDevice.model == "iPhone Simulator"

FLURRY_TOKEN = '7XM69ZGBXJVDYCP22PS2'
FLURRY_ENABLED = YES

CRITTERCISM_APP_ID = '553bfc617365f84f7d3d6fa6'

SHOW_AD_AFTER_PHOTO_VIEWS = 15
SHOW_AD_CHART_VIEW_IPHONE = 30
SHOW_AD_CHART_VIEW_IPAD = 100

def pp(*args)
  puts "*** " + args.map(&:inspect).join(', ')
end

def __assert(condition)
  raise unless condition
end

def __p(*args)
  inspection = args.inspect[1...-1]
  puts "--- #{inspection}"
end

# def __p(label, *args)
#   inspection = ": #{args.inspect[1...-1]}" if args.any?
#   puts "--- #{label}#{inspection}"
# end

alias __P __p

def __pla(array)
  array.each do |item|
    puts "--- #{item.inspect}"
  end
  nil
end

def debug_raise(message, result = '')
  raise(message) if DEBUG
  result
end