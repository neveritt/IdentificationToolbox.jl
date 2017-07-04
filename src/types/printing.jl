import SystemsBase: _mfdtype, _dimensions, _time, _timevar, _printsamplingtime


# IdStateSpace
_printxupdate{T}(s::IdStateSpace{Val{T},Val{:cont}})  = "ẋ(t)"
_printxupdate{T}(s::IdStateSpace{Val{T},Val{:disc}})  = "x(k+1)"

summary{T}(s::IdStateSpace{Val{:siso},Val{T}})  = "IdStateSpace"
summary{T}(s::IdStateSpace{Val{:mimo},Val{T}})  = "$(_dimensions(s)) IdStateSpace"

# Compact representations
function _compact{T,S}(stream, ::MIME"text/plain", s::IdStateSpace{Val{T},Val{S}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "G($(var))")
end

function _compact{T,S}(stream, ::MIME"text/latex", s::IdStateSpace{Val{T},Val{S}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "\$")
  print(stream, "G($(var))")
  print(stream, "\$")
end

# TODO: Think about text/html

# Full representations
function _full{T,S}(stream, m::MIME"text/plain", s::IdStateSpace{Val{T},Val{S}})
  tvar = _timevar(s)
  println(stream, summary(s))
  println(stream, "$(_printxupdate(s)) = Ax($tvar) + Bu($tvar,x) + Ke(t)")
  println(stream, "y($tvar) = Cx($tvar) + Du($tvar,x) + e(t)")
  println(stream, "with $(numstates(s)) states in $(_time(s)) time.")
end

function _full{T,S}(stream, m::MIME"text/latex", s::IdStateSpace{Val{T},Val{S}})
  tvar = _timevar(s)
  println(stream, summary(s))
  print(stream, "\\begin{align*}")
  println(stream, "$(_printxupdate(s)) &= Ax($tvar) + Bu($tvar,x) + Ke(t)")
  println(stream, "y($tvar) &= Cx($tvar) + Du($tvar,x) + e(t)")
  print(stream, "\\begin{align*}")
  println(stream, "with $(numstates(s)) states in $(_time(s)) time.")
end

# TODO: Think about text/html

# `show` function
@compat Base.show(stream::IO, s::IdStateSpace)                          =
  Base.show(stream, MIME("text/plain"), s)
@compat Base.show(stream::IO, mime::MIME"text/plain", s::IdStateSpace)  =
  get(stream, :compact, false) ? _compact(stream, mime, s) : _full(stream, mime, s)
@compat Base.show(stream::IO, mime::MIME"text/latex", s::IdStateSpace)  =
  get(stream, :compact, false) ? _compact(stream, mime, s) : _full(stream, mime, s)


# IdMFD
_mfdtype{S,T,L}(::IdMFD{Val{S},Val{T},Val{L}}) = ifelse(L == :lfd, "Left", "Right")

summary{S,L}(s::IdMFD{Val{:siso},Val{S},Val{L}}) =
  "Identified $(SystemsBase._mfdtype(s)) MatrixFractionDescription"
summary{S,L}(s::IdMFD{Val{:mimo},Val{S},Val{L}}) =
  "$(SystemsBase._dimensions(s)) Identified $(SystemsBase._mfdtype(s)) MatrixFractionDescription"

# Compact representations
function _compact{T,S}(stream, ::MIME"text/plain", s::IdMFD{Val{T},Val{S},Val{:lfd}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "d($(var))", "\\", "n($(var))")
end

function _compact{T,S}(stream, ::MIME"text/plain", s::IdMFD{Val{T},Val{S},Val{:rfd}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "n($(var))/d($(var))")
end

function _compact{T,S}(stream, ::MIME"text/latex", s::IdMFD{Val{T},Val{S},Val{:lfd}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "\$")
  print(stream, "d($(var))", "\\", "n($(var))")
  print(stream, "\$")
end

function _compact{T,S}(stream, ::MIME"text/latex", s::IdMFD{Val{T},Val{S},Val{:rfd}})
  var = ifelse(S == :cont, "s", "z")
  print(stream, "\$")
  print(stream, "n($(var))/d($(var))")
  print(stream, "\$")
end

# TODO: Think about text/html

# Full representations
function _full{T,S}(stream, m::MIME"text/plain", s::IdMFD{Val{T},Val{S},Val{:lfd}})
  var  = ifelse(S == :cont, "s", "z")
  tvar = _timevar(s)
  println(stream, summary(s))
  println(stream, "y($tvar) = den($var)", "\\", "num($var) u($tvar)")
  println(stream, "in $(_time(s)) time.")
end

function _full{T,S}(stream, m::MIME"text/plain", s::IdMFD{Val{T},Val{S},Val{:rfd}})
  var  = ifelse(S == :cont, "s", "z")
  tvar = _timevar(s)
  println(stream, summary(s))
  println(stream, "y($tvar) = num($var)/den($var) u($tvar)")
  println(stream, "in $(_time(s)) time.")
end

function _full{T,S}(stream, m::MIME"text/latex", s::IdMFD{Val{T},Val{S},Val{:lfd}})
  var  = ifelse(S == :cont, "s", "z")
  tvar = _timevar(s)
  println(stream, summary(s))
  print(stream, "\$\$")
  print(stream, "y($tvar) = den^{-1}($var)num($var) u($tvar)")
  print(stream, "\$\$")
  println(stream, "in $(_time(s)) time.")
end

function _full{T,S}(stream, m::MIME"text/latex", s::IdMFD{Val{T},Val{S},Val{:rfd}})
  var  = ifelse(S == :cont, "s", "z")
  tvar = _timevar(s)
  println(stream, summary(s))
  print(stream, "\$\$")
  print(stream, "y($tvar) = num($var)den^{-1}($var) u($tvar)")
  print(stream, "\$\$")
  println(stream, "in $(_time(s)) time.")
end

# TODO: Think about text/html

# `show` function
@compat Base.show(stream::IO, s::IdMFD)                          =
  Base.show(stream, MIME("text/plain"), s)
@compat Base.show(stream::IO, mime::MIME"text/plain", s::IdMFD)  =
  get(stream, :compact, false) ? _compact(stream, mime, s) : _full(stream, mime, s)
@compat Base.show(stream::IO, mime::MIME"text/latex", s::IdMFD)  =
  get(stream, :compact, false) ? _compact(stream, mime, s) : _full(stream, mime, s)
