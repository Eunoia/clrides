# polyline_decoder.rb by George Lantz August 2007
# modified by EvanR August 2011
# Usage Example:
#
# line = "{b~zEdruxPT?L|@PP"
# line_arr = PolylineDecode::decode(line)
#
# line_arr.each do |ln|
#   puts ln[0].to_s  + ", " + ln[1].to_s
# end



class PolylineDecoder
	def self::decode(polyline)
      encoded = polyline
      len = encoded.length
      index = 0
      array = Array.new
      lat = 0
      lng = 0
      while (index < len)
        shift = 0
        result = 0
        loop do
          a = encoded[index]
          b = a - 63
          result |= (b & 0x1f) << shift
          shift += 5
          index += 1
          break unless (b >= 0x20)
        end
        dlat = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1))
        lat += dlat
        shift = 0
        result = 0
        loop do
          a = encoded[index]
          b = a - 63
          result |= (b & 0x1f) << shift
          shift += 5
          index += 1
          break unless (b >= 0x20)
        end
        dlng = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1))
        lng += dlng
        array.push([lat * 1e-5, lng * 1e-5])
      end
      return array
  end
end
