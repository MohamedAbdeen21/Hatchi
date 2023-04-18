package connectors

import (
	pb "Hatchi/backend/proto"
	"context"
	"fmt"
)

// Connectors' server struct
type ConnectorServer struct {
	pb.DatabaseConnectServer
	Databases map[string]connector
	Current   connector
}

// factory function; creates and returns a ConnectorServer struct
func NewConnectorServer() *ConnectorServer {
	return &ConnectorServer{
		Databases: databases,
		Current:   nil,
	}
}

// pass query to connector to execute
func (c *ConnectorServer) Execute(ctx context.Context, query *pb.Query) (*pb.QueryResult, error) {
	return c.Current.Execute(ctx, query)
}

// change current database
func (c *ConnectorServer) SelectConnector(
	ctx context.Context,
	name *pb.ConnectorName,
) (*pb.Empty, error) {
	var exists bool
	c.Current, exists = c.Databases[name.Name]

	// name provided is not a connector
	if !exists {
		// return error message with all available connectors
		return nil, fmt.Errorf(
			"no connector with name %s, available: %v",
			name.Name,
			c.getAllConnectors(),
		)
	}

	return &pb.Empty{}, nil
}

func (c *ConnectorServer) ListConnectors(ctx context.Context, _ *pb.Empty) (*pb.Connectors, error) {
	return &pb.Connectors{Names: c.getAllConnectors()}, nil
}

func (c *ConnectorServer) getAllConnectors() []string {
	var allConnectorNames []string

	// iterate over the names of the connectors and append to list
	for connectorName := range c.Databases {
		allConnectorNames = append(allConnectorNames, connectorName)
	}

	return allConnectorNames
}
