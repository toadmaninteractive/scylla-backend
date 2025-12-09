@echo off

setlocal enableextensions enableDelayedExpansion

set ERLANG_OTP_VERSION=27.0.1
set ELIXIR_VERSION=1.18.4

SET PATH=C:\Erlang\erl-%ERLANG_OTP_VERSION%\bin;C:\Elixir\%ELIXIR_VERSION%\bin;%PATH%
set MIX_ENV=prod

echo === Installing prerequisites...
call mix local.hex --force
if errorlevel 1 pause & exit

call mix local.rebar --force
if errorlevel 1 pause & exit

echo === Fetching dependencies...
call mix deps.get
if errorlevel 1 pause & exit

echo === Compiling...
call mix compile
if errorlevel 1 pause & exit

echo === Generating release...
call mix release server_windows --force --overwrite
if errorlevel 1 pause & exit

endlocal
