@[Link(ldflags: "-L #{__DIR__} -l:kexpr.so")]
lib Kexpr
  fun parse = ke_parse(_s : LibC::Char*, err : LibC::Int*) : KexprT
  type KexprT = Void*
  fun destroy = ke_destroy(ke : KexprT)
  fun set_int = ke_set_int(ke : KexprT, var : LibC::Char*, x : Int64T) : LibC::Int
  alias X__Int64T = LibC::Long
  alias Int64T = X__Int64T
  fun set_real = ke_set_real(ke : KexprT, var : LibC::Char*, x : LibC::Double) : LibC::Int
  fun set_str = ke_set_str(ke : KexprT, var : LibC::Char*, x : LibC::Char*) : LibC::Int
  fun set_real_func1 = ke_set_real_func1(ke : KexprT, name : LibC::Char*, func : (LibC::Double -> LibC::Double)) : LibC::Int
  fun set_real_func2 = ke_set_real_func2(ke : KexprT, name : LibC::Char*, func : (LibC::Double, LibC::Double -> LibC::Double)) : LibC::Int
  fun set_default_func = ke_set_default_func(ke : KexprT) : LibC::Int
  fun unset = ke_unset(e : KexprT)
  fun eval = ke_eval(ke : KexprT, _i : Int64T*, _r : LibC::Double*, _s : LibC::Char**, ret_type : LibC::Int*) : LibC::Int
  fun eval_int = ke_eval_int(ke : KexprT, err : LibC::Int*) : Int64T
  fun eval_real = ke_eval_real(ke : KexprT, err : LibC::Int*) : LibC::Double
  fun print = ke_print(ke : KexprT)
end
