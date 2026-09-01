package client

import "core:fmt"
import "core:net"

main :: proc() {
    // 1. Identify the receptionist's desk
    endpoint := net.Endpoint{
        address = net.IP4_Loopback,
        port    = 8080,
    }

    // 2. Dispatch the courier (connect to the server)
    // We use dial_tcp to initiate the handshake.
    socket, dial_err := net.dial_tcp_from_endpoint(endpoint)
    if dial_err != nil {
        fmt.eprintfln("Failed to connect. Is the server running? %v", dial_err)
        return
    }
    
    // BEST PRACTICE: Defer the closure immediately after a successful connection.
    // If the program crashes or exits early, the OS will still release the socket.
    defer net.close(socket)

    // 3. Write down our standardized request form
    // A valid HTTP GET request requires the path ('/'), the protocol, and the Host header.
    request := "GET / HTTP/1.1\r\nHost: 127.0.0.1:8080\r\nConnection: close\r\n\r\n"

    // 4. Hand the request over the desk
    // transmute() changes how the compiler views the string, treating it as raw bytes.
    _, send_err := net.send_tcp(socket, transmute([]byte)request)
    if send_err != nil {
        fmt.eprintfln("Failed to send request: %v", send_err)
        return
    }

    // 5. Wait for the folder to come back
    // BEST PRACTICE: Use a fixed-size stack buffer to catch the incoming data.
    buffer: [2048]byte
    bytes_read, read_err := net.recv_tcp(socket, buffer[:])
    if read_err != nil {
        fmt.eprintfln("Failed to read response: %v", read_err)
        return
    }

    // 6. Read the contents out loud
    // Slicing the buffer to `bytes_read` prevents printing empty garbage memory.
    response_text := string(buffer[:bytes_read])
    
    fmt.println("--- Server Response ---")
    fmt.println(response_text)
}
