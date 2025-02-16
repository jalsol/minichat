# minichat

![minichat example](https://i.imgur.com/UT8JMI3.png)

**minichat** is a minimalistic one-on-one server-client chat application implemented in OCaml.
It serves as a simple example of network communication and concurrency in OCaml.

It currently only supports Linux-based OS (I assume it can run on other Unix-based OS as well, but not tested).

## Installation

1. **Clone the Repository**:

```sh
git clone https://github.com/jalsol/minichat.git
cd minichat
```

2. **Install Dependencies**:

Use opam to install the required dependencies:

```sh
opam install . --deps-only
```

3. **Build the Project**:

Compile the project using Dune:

```sh
dune build
```

This will generate the executable in the `_build` directory.

## Usage

1. **Start the Server**:

On a server, run the application in server mode:

```sh
dune exec -- minichat -m server -p <port>
```

The server will start and listen for incoming client connections.

2. **Start a Client**:

In another machine/terminal session, run the application in client mode:

```sh
dune exec -- minichat -m client -h <address> -p <port>
```

3. **Chat**:

Type messages in either the server or the client terminal, and press Enter to send.
Messages will appear at the recipient end. The sender end will also display the RTT. 

## License

This project is licensed under The Unlicense. See the [LICENSE](LICENSE) file for details.
