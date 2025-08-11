require "./kexpr"

class KE
  # Parse errors
  KEE_UNQU = 0x01 # unmatched quotation marks
  KEE_UNLP = 0x02 # unmatched left parentheses
  KEE_UNRP = 0x04 # unmatched right parentheses
  KEE_UNOP = 0x08 # unknown operators
  KEE_FUNC = 0x10 # wrong function syntax
  KEE_ARG  = 0x20
  KEE_NUM  = 0x40 # fail to parse a number

  # Evaluation errors
  KEE_UNFUNC = 0x40 # undefined function
  KEE_UNVAR  = 0x80 # unassigned variable

  def initialize(s : String)
    @err = Pointer(Int32).malloc
    @ke = Kexpr.parse(s, @err)
    err = @err.value
    if err != 0
      raise "#{parse_error(err)} (#{err})"
    end
  end

  def clear
    @err.value = 0
    Kexpr.unset(@ke) unless @ke.null?
  end

  def finalize
    Kexpr.destroy(@ke)
  end

  def to_unsafe
    @ke
  end

  def bool
    Kexpr.eval_real(@ke, @err).abs > 1e-8
  end

  def error_code
    @err.value
  end

  def parse_error(err = error_code)
    if err == 0
      "no error"
    elsif (err & KEE_UNQU) != 0
      "unmatched quotation marks"
    elsif (err & KEE_UNLP) != 0
      "unmatched left parentheses"
    elsif (err & KEE_UNRP) != 0
      "unmatched right parentheses"
    elsif (err & KEE_UNOP) != 0
      "unknown operators"
    elsif (err & KEE_FUNC) != 0
      "wrong function syntax"
    elsif (err & KEE_ARG) != 0
      "wrong arguments"
    elsif (err & KEE_NUM) != 0
      "fail to parse a number"
    else
      "unknown error"
    end
  end

  def eval_error(err = error_code)
    if err == 0
      "no error"
    elsif (err & KEE_UNFUNC) != 0
      "undefined function"
    elsif (err & KEE_UNVAR) != 0
      "unassigned variable"
    else
      "unknown error"
    end
  end

  def set(name : String, v : (Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64))
    Kexpr.set_int(@ke, name, v)
  end

  def set(name : String, v : (Float32 | Float64))
    Kexpr.set_real(@ke, name, v)
  end

  def set(name : String, v : String)
    Kexpr.set_str(@ke, name, v)
  end

  def set(name : String, v : Char)
    Kexpr.set_str(@ke, name, v.to_s)
  end

  def print
    Kexpr.print(@ke)
  end
end
