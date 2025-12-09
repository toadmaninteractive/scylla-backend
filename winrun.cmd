@echo off

setlocal enableextensions enableDelayedExpansion

set ERLANG_OTP_VERSION=27.0.1
set ELIXIR_VERSION=1.18.4

SET PATH=C:\Erlang\erl-%ERLANG_OTP_VERSION%\bin;C:\Elixir\%ELIXIR_VERSION%\bin;%PATH%
set MIX_ENV=prod

call mix ecto.create ecto.migrate
call iex -S mix

endlocal
