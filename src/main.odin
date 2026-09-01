package main

import "core:fmt"
import "core:net"

main :: proc() {
    // 1. Define the Endpoint
    // IP4_Loopback (127.0.0.1) restricts traffic to your local machine.
    endpoint := net.Endpoint{
        address = net.IP4_Loopback,
        port    = 8080,
    }

    // 2. Open the server socket
    server_socket, listen_err := net.listen_tcp(endpoint)
    if listen_err != nil {
        fmt.eprintfln("Failed to listen: %v", listen_err)
        return
    }
    
    // BEST PRACTICE: 'defer' ensures the socket is cleanly shut down 
    // exactly when main() finishes executing, preventing port lockouts.
    defer net.close(server_socket)

    fmt.println("Server is running at http://127.0.0.1:8080")

    // 3. Enter the continuous loop to accept visitors
    for {
        client_socket, client_endpoint, accept_err := net.accept_tcp(server_socket)
        if accept_err != nil {
            fmt.eprintfln("Failed to accept client: %v", accept_err)
            continue
        }

        // 4. Delegate to a dedicated procedure to handle the interaction
        handle_client(client_socket)
    }
}

handle_client :: proc(client: net.TCP_Socket) {
    // BEST PRACTICE: Close the client connection the moment this function exits.
    defer net.close(client)

    // 5. Read the visitor's HTTP request
    // We allocate a fixed buffer to store the incoming text.
    buffer: [1024]byte

    bytes_read, read_err := net.recv_tcp(client, buffer[:])
    if read_err != nil {
        fmt.eprintfln("Read error: %v", read_err)
        return
    }

    // 6. Construct the raw HTTP response
    // HTTP requires explicit carriage-return line breaks (\r\n) 
    // and an empty line separating the headers from the body content.
    response := "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<h1>Hello from Odin!</h1>"

    // Convert the string memory representation to raw bytes and push it back through the socket.
    _, send_err := net.send_tcp(client, transmute([]byte)response)
    if send_err != nil {
        fmt.eprintfln("Send error: %v", send_err)
    }
}
