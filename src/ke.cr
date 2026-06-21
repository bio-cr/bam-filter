require "anyolite"
require "set"

class KE
  alias Value = (Bool | Int64 | Float64 | String | Array(Int64) | Array(Float64))?

  @rb : Anyolite::RbInterpreter
  @names : Array(String)
  @values : Array(Value)
  @index : Hash(String, Int32)
  @proc : Anyolite::RbRef
  @last_error : String?

  RUBY_KEYWORDS = Set{
    "BEGIN", "END", "alias", "and", "begin", "break", "case", "class",
    "def", "defined", "do", "else", "elsif", "end", "ensure", "false",
    "for", "if", "in", "module", "next", "nil", "not", "or", "redo",
    "rescue", "retry", "return", "self", "super", "then", "true",
    "undef", "unless", "until", "when", "while", "yield",
  }

  getter error_code : Int32 = 0

  def initialize(@expr : String, require_files : Array(String) = [] of String)
    @rb = Anyolite::RbInterpreter.new
    Anyolite::HelperClasses.load_all(@rb)
    Anyolite.disable_program_execution
    load_require_files(require_files)
    @names = identifiers(@expr)
    @values = Array(Value).new(@names.size, nil)
    @index = Hash(String, Int32).new
    @names.each_with_index { |name, i| @index[name] = i }
    @proc = compile(@expr)
  end

  def clear
    @error_code = 0
    @last_error = nil
    @values.fill(nil)
    clear_ruby_error
  end

  def finalize
    @rb.close
  end

  def bool
    rb = @rb.to_unsafe
    arena = Anyolite::RbCore.rb_gc_arena_save(rb)
    result = Anyolite.call_rb_method_of_object(@proc, "call", @values)
    if error = last_ruby_error
      @error_code = 1
      @last_error = error
      clear_ruby_error
      Anyolite::RbCore.rb_gc_arena_restore(rb, arena)
      return false
    end
    value = truthy?(result)
    Anyolite::RbCore.rb_gc_arena_restore(rb, arena)
    value
  end

  def parse_error(err = error_code)
    err == 0 ? "no error" : (@last_error || "Ruby parse error")
  end

  def eval_error(err = error_code)
    err == 0 ? "no error" : (@last_error || "Ruby evaluation error")
  end

  def set(name : String, v : (Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64))
    set_value(name, v.to_i64)
  end

  def set(name : String, v : Bool)
    set_value(name, v)
  end

  def set(name : String, v : (Float32 | Float64))
    set_value(name, v.to_f64)
  end

  def set(name : String, v : String)
    set_value(name, v)
  end

  def set(name : String, v : Char)
    set_value(name, v.to_s)
  end

  def set(name : String, v : Array(Int64) | Array(Float64))
    set_value(name, v)
  end

  def print
    puts @expr
  end

  private def identifiers(expr : String)
    names = [] of String
    expr.scan(/[A-Za-z_][A-Za-z0-9_]*/) do |match|
      name = match[0]
      next if RUBY_KEYWORDS.includes?(name)
      next unless variable_name?(name)
      names << name unless names.includes?(name)
    end
    names
  end

  private def variable_name?(name : String)
    case name
    when "name", "flag", "chr", "pos", "start", "stop", "mapq", "mchr", "mpos", "isize",
         "paired", "proper_pair", "unmapped", "mate_unmapped", "reverse", "mate_reverse",
         "read1", "read2", "secondary", "qcfail", "duplicate", "supplementary"
      true
    else
      name.starts_with?("tag_")
    end
  end

  private def compile(expr : String)
    params = @names.join(", ")
    code = "->(#{params}) { #{expr} }"
    result = @rb.execute_script_line(code, clear_error: false)
    if error = last_ruby_error
      @error_code = 1
      @last_error = error
      clear_ruby_error
      @rb.close
      raise parse_error
    end
    Anyolite::RbRef.new(result)
  end

  private def load_require_files(files : Array(String))
    files.each do |path|
      begin
        code = File.read(path)
      rescue ex : Exception
        @rb.close
        raise "failed to read require file #{path}. #{ex.message}"
      end

      @rb.execute_script_line(code, clear_error: false)
      if error = last_ruby_error
        @error_code = 1
        @last_error = error
        clear_ruby_error
        @rb.close
        raise "failed to load require file #{path}. #{@last_error}"
      end
    end
  end

  private def set_value(name : String, value : Value)
    if i = @index[name]?
      @values[i] = value
    end
  end

  private def truthy?(result : Anyolite::RbRef)
    value = result.value
    return false if Anyolite::RbCast.check_for_nil(value)
    return false if Anyolite::RbCast.check_for_false(value)
    return Anyolite::RbCore.get_rb_fixnum(value) != 0 if Anyolite::RbCast.check_for_fixnum(value)
    return Anyolite::RbCore.get_rb_float(value).abs > 1e-8 if Anyolite::RbCast.check_for_float(value)
    true
  end

  private def last_ruby_error
    error = Anyolite::RbCore.get_last_rb_error(@rb)
    return if Anyolite::RbCast.check_for_nil(error)
    rb = @rb.to_unsafe
    Anyolite::RbCast.cast_to_string(rb, Anyolite::RbCore.rb_inspect(rb, error))
  end

  private def clear_ruby_error
    Anyolite::RbCore.clear_last_rb_error(@rb)
  end
end
