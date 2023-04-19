package connectors

import (
	"context"

	pb "Hatchi/backend/proto"
)

// add new connectors here
var Connectors = []Connector{
	newSqliteConnector(),
}

// methods the connector must implement
type Connector interface {
	Name() string
	Execute(context.Context, *pb.Query) (*pb.QueryResult, error)
	ListConnectionOptions() (*pb.ConnectionOptions, error)
	Connect(context.Context, *pb.ConnectionOptions) error
}
