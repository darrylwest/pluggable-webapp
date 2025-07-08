# Unix Sockets

Node.js has excellent, built-in support for Unix sockets.

They are a core feature of the net and http modules, making them a first-class citizen for Inter-Process Communication (IPC) on Unix-like systems (Linux, macOS, etc.).

How it Works
Instead of listening on a TCP port (like 8080), a Node.js server can listen on a special file on the filesystem, which is the Unix socket. Any process on the same machine with the correct permissions can then connect to that file to communicate with the server.

The key difference in Node.js code is simple: when you call the .listen() method, you provide a file path instead of a port number.

1. Basic Server and Client (using the net module)
This is for raw, TCP-like stream communication.

Unix Socket Server (server.js)
Notice the cleanup code for the socket file. This is important because if your server crashes, the socket file might be left behind, preventing a restart.

Generated javascript
const net = require('net');
const fs = require('fs');

const SOCKET_PATH = '/tmp/my-app.sock';

// Clean up the socket file if it already exists
if (fs.existsSync(SOCKET_PATH)) {
  fs.unlinkSync(SOCKET_PATH);
}

const server = net.createServer((client) => {
  console.log('Client connected!');

  client.on('data', (data) => {
    console.log(`Received data from client: ${data.toString()}`);
    client.write('Hello from the server!');
  });

  client.on('end', () => {
    console.log('Client disconnected.');
  });

  client.on('error', (err) => {
    console.error('Client error:', err);
  });
});

server.listen(SOCKET_PATH, () => {
  console.log(`Server listening on Unix socket: ${SOCKET_PATH}`);
});

// Gracefully shut down and clean up the socket file
process.on('SIGINT', () => {
  console.log('Shutting down server...');
  server.close(() => {
    fs.unlinkSync(SOCKET_PATH);
    process.exit(0);
  });
});
content_copy
download
Use code with caution.
JavaScript
Unix Socket Client (client.js)
Generated javascript
const net = require('net');

const SOCKET_PATH = '/tmp/my-app.sock';

const client = net.createConnection({ path: SOCKET_PATH }, () => {
  console.log('Connected to server!');
  client.write('Hi, this is the client.');
});

client.on('data', (data) => {
  console.log(`Received data from server: ${data.toString()}`);
  client.end(); // Close the connection after getting a response
});

client.on('end', () => {
  console.log('Disconnected from server.');
});

client.on('error', (err) => {
  console.error('Connection error:', err.message);
});
content_copy
download
Use code with caution.
JavaScript
To run this:

node server.js
In another terminal: node client.js
2. HTTP Server over a Unix Socket
This is a very common and powerful use case, especially when putting a reverse proxy like Nginx in front of your Node.js application.

HTTP Server (http-server.js)
Generated javascript
const http = require('http');
const fs = require('fs');

const SOCKET_PATH = '/tmp/my-http-app.sock';

// Clean up old socket
if (fs.existsSync(SOCKET_PATH)) {
  fs.unlinkSync(SOCKET_PATH);
}

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    message: 'Hello from your HTTP server on a Unix socket!',
    url: req.url
  }));
});

server.listen(SOCKET_PATH, () => {
  // Set permissions so the web server (e.g., nginx) can access the socket
  fs.chmodSync(SOCKET_PATH, '777'); // Or more restrictive permissions
  console.log(`HTTP server listening on Unix socket: ${SOCKET_PATH}`);
});
content_copy
download
Use code with caution.
JavaScript
To test this server:
You can use curl with the --unix-socket flag.

Run the server: node http-server.js
In another terminal, run curl:
Generated bash
# The 'localhost' part is just a placeholder, but it's required by curl
curl --unix-socket /tmp/my-http-app.sock http://localhost/some/path
content_copy
download
Use code with caution.
Bash
You will see the JSON response from your server.
Advantages of Using Unix Sockets
Performance: They are significantly faster than TCP/IP sockets for communication on the same machine. They avoid the overhead of the network stack (no routing, packet encapsulation, checksums, etc.). Data is passed directly through the kernel's memory buffers.
Security: Since the socket is a file on the filesystem, you can use standard Unix file permissions (chmod, chown) to control which users or groups can access it. This provides a robust access control mechanism that isn't available with TCP ports (which are open to any process on the machine unless firewalled).
No Port Conflicts: You don't have to worry about finding an available TCP port or dealing with port conflicts between different applications on the same server.
Common Use Cases
Reverse Proxies: The most common use case. A web server like Nginx or Apache listens on port 80/443 and proxies requests to a Node.js application listening on a Unix socket. This is more efficient and secure than proxying to localhost:3000.
Database Connections: Connecting to a local database server (like PostgreSQL or MySQL) that is configured to accept connections via a socket.
IPC between Microservices: If you have multiple services (e.g., written in Node.js, Python, Ruby) running on the same host, they can communicate efficiently and securely using Unix sockets.
A Note on Windows
True Unix sockets are not available on Windows. However, Node.js provides an abstraction over a similar Windows-specific mechanism called named pipes. You can use the same net module code, but the path will look different (e.g., \\.\pipe\my-pipe). The Node.js documentation transparently handles this distinction for you.

