package main

import (
	"Hatchi/backend/connectors"
	pb "Hatchi/backend/proto"
	"context"
	"fmt"
)

// Connectors' server struct
type ConnectorServer struct {
	pb.DatabaseConnectServer
	Databases map[string]connectors.Connector
	Current   connectors.Connector
	Previous  connectors.Connector
}

// factory function; creates and returns a ConnectorServer struct
func newConnectorServer() *ConnectorServer {
	// map connectors to their names
	conns := make(map[string]connectors.Connector, len(connectors.Connectors))
	for _, connector := range connectors.Connectors {
		conns[connector.Name()] = connector
	}

	return &ConnectorServer{
		Databases: conns,
		Current:   nil,
	}
}

// change current database connector
func (c *ConnectorServer) SelectConnector(
	ctx context.Context,
	name *pb.ConnectorName,
) (*pb.ConnectionOptions, error) {
	conn, exists := c.Databases[name.Name]

	// name provided is not an connector
	if !exists {
		return nil, fmt.Errorf(
			"no connector with name %s, available: %v",
			name.Name,
			c.getAllConnectors(),
		)
	}

	return conn.ListConnectionOptions()
}

func (c *ConnectorServer) Connect(
	ctx context.Context,
	options *pb.ConnectionOptions,
) (*pb.Empty, error) {
	var exists bool
	c.Previous = c.Current
	c.Current, exists = c.Databases[options.ConnectorName]
	if !exists {
		c.Current = c.Previous
		return nil, fmt.Errorf(
			"no connector with name %s, available: %v",
			options.ConnectorName,
			c.getAllConnectors(),
		)
	}

	return &pb.Empty{}, c.Current.Connect(ctx, options)
}

// pass query to current connector to execute
func (c *ConnectorServer) Execute(ctx context.Context, query *pb.Query) (*pb.QueryResult, error) {
	return c.Current.Execute(ctx, query)
}

// Return a list of all available connectors
func (c *ConnectorServer) ListConnectors(
	ctx context.Context,
	_ *pb.Empty,
) (*pb.ConnectorsList, error) {
	return &pb.ConnectorsList{Names: c.getAllConnectors()}, nil
}

// return a list of the names of all available connectors
func (c *ConnectorServer) getAllConnectors() []string {
	var allConnectorNames []string

	// iterate over the names of the connectors and append to list
	for connectorName := range c.Databases {
		allConnectorNames = append(allConnectorNames, connectorName)
	}

	return allConnectorNames
}
