@echo off

setlocal enableextensions enableDelayedExpansion

SET ERLANG_OTP_VERSION=23.3
SET ELIXIR_VERSION=1.12.3

SET PATH=C:\Erlang\erl-%ERLANG_OTP_VERSION%\bin;C:\Elixir\%ELIXIR_VERSION%\bin;%PATH%
set MIX_ENV=prod

call mix ecto.create ecto.migrate
call iex -S mix

endlocal
