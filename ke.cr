require "./kexpr"

class KE
  def initialize(s : String)
    @err = Pointer(Int32).malloc
    @ke = Kexpr.parse(s, @err)
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

  def error
    @err.value
  end

  def set(name : String, v : Int)
    Kexpr.set_int(@ke, name, v)
    error
  end

  def set(name : String, v : UInt8)
    Kexpr.set_int(@ke, name, v.as(Int))
    error
  end

  def set(name : String, v : String)
    Kexpr.set_str(@ke, name, v)
    error
  end
end