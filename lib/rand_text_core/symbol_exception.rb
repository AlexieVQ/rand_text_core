require_relative '../rand_text_core'
require_relative 'rtc_exception'

# Exception class for exceptions raised when symbols already exist or does not
# exist in a SymbolTable.
#
# @author AlexieVQ
class RandTextCore::SymbolException < RandTextCore::RTCException
end