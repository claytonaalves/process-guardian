# Process guardian

Runs one or more processes and restarts them, if them crashes.

# Config file

```
[MyApp]
command = c:\bin\myapp.exe
params = xxx yyy
check-network = yes
retries = 5
working-dir = C:\bin

[MyAnotherApp]
command = c:\Windows\other.exe
working-dir = C:\windows
```
