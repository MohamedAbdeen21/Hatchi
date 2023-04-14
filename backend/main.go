package main

import (
	"Hatchi/backend/connectors"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	pb "Hatchi/backend/proto"

	_ "github.com/mattn/go-sqlite3"
	"google.golang.org/grpc"
)

// Gracefully shutdown the server if an interrupt happens
func killOnInterrupt(server *grpc.Server, c chan os.Signal) {
	// Reading from an empty channel blocks.
	// Unblock when data is written to channel.
	sig := <-c
	log.Printf("\nCaught signal %s, shutting down.\n", sig)
	server.Stop()
	os.Exit(0)
}

func main() {
	// setup UDS socket
	// instead, for a tcp socket, use: listener, err := net.Listen("tcp", "localhost"+port)
	laddr, err := net.ResolveUnixAddr("unix", "/tmp/test.socket")
	listener, err := net.ListenUnix("unix", laddr)
	if err != nil {
		log.Fatalf("Failed to start the server %v", err)
	}

	grpcServer := grpc.NewServer()

	// close the socket when the server is killed
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt, os.Kill, syscall.SIGTERM)
	go killOnInterrupt(grpcServer, signalChannel)

	// register the service and start the gRPC server
	server := connectors.NewConnectorServer()
	pb.RegisterDatabaseConnectServer(grpcServer, server)

	// serve the server
	log.Printf("Server started at %v", listener.Addr())
	if err := grpcServer.Serve(listener); err != nil {
		log.Fatalf("Failed to start gRPC server %v", err)
	}
}
