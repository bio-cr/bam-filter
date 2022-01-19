@[Include(
  "kexpr.h",
  flags: "-I#{__DIR__} -fPIC",
  prefix: "ke_",
)]
@[Link("kexpr")]
lib Kexpr
  fun ke_set_int
end
