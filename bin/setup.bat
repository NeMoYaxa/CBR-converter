@echo off
echo --- Installing dependencies ---
call bundle install

echo.
echo --- Configuring Git hooks ---
call git config core.hooksPath .githooks

echo.
echo --- Success! Project is ready ---
pause